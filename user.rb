# encoding: utf-8
require 'data_mapper'
require 'slim'

module Assassins
  class App < Sinatra::Base
    helpers do
      def logged_in?
        session.has_key? :player_id
      end

      def user
        if session.has_key? :player_id
          Player.get session[:player_id]
        else
          nil
        end
      end
    end

    get '/login' do
      slim :login
    end

    post '/login' do
      if !params.has_key?('andrew_id')
        return redirect to('/')
      end
      player = Player.first(:andrew_id => params['andrew_id'])

      if (player.nil?)
        return slim :login, :locals => {:errors =>
          ['Invalid Andrew ID. Please try again.']}
      end

      if (!player.active?)
        if (!player.is_verified)
          return redirect to('/signup/resend_verification')
        else
          return slim :login, :locals => {:errors =>
            ['You have been killed and your account made inactive. Thanks for playing!']}
        end
      end

      if (!(params.has_key?('secret') &&
            params['secret'].casecmp(player.secret) == 0))
        return slim :login, :locals => {:errors =>
          ['Incorrect secret words. Please try again.']}
      end

      session[:player_id] = player.id
      redirect to('/dashboard')
    end

    get '/logout' do
      session.delete :player_id
      redirect to('/')
    end

    get '/signup' do
      slim :signup
    end

    post '/signup' do
      player = Player.new(:name => params['name'],
                          :andrew_id => params['andrew_id'],
                          :floor_id => params['floor'],
                          :program_id => params['program'])
      player.generate_secret! 2
      if (player.save)
        player.send_verification(settings.mailer, url("/signup/verify?aid=#{player.andrew_id}&nonce=#{player.verification_key}"))
        slim :signup_confirm
      else
        slim :signup, :locals => {:errors => player.errors.full_messages}
      end
    end

    get '/signup/resend_verification' do
      slim :resend_verification
    end

    post '/signup/resend_verification' do
      if !params.has_key?('andrew_id')
        return redirect to('/')
      end
      player = Player.first(:andrew_id => params['andrew_id'])

      if (!player.nil? && !player.is_verified)
        player.verification_key = SecureRandom.uuid
        player.save!
        player.send_verification(settings.mailer, url("/signup/verify?aid=#{player.andrew_id}&nonce=#{player.verification_key}"))
        slim :signup_confirm
      else
        redirect to('/')
      end
    end

    get '/signup/verify' do
      if !params.has_key?('aid')
        return redirect to('/')
      end
      player = Player.first(:andrew_id => params['aid'])

      if (player.nil? || player.is_verified)
        return redirect to('/')
      end

      if (params.has_key?('nonce') && params['nonce'] == player.verification_key)
        player.is_verified = true;
        player.save!;
        session[:player_id] = player.id
        redirect to('/dashboard')
      else
        redirect to('/')
      end
    end

    get '/dashboard' do
      if !user.nil?
        slim :dashboard
      else
        redirect to('/login')
      end
    end
 end
end

# vim:set ts=2 sw=2 et:
