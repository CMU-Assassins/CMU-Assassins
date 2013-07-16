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
      if params.has_key?('andrew_id')
        player = Player.first(:andrew_id => params['andrew_id'])
        if (!player.nil? && params.has_key?('secret') &&
            params['secret'].casecmp(player.secret) == 0)
          redirect to('/dashboard')
        else
          redirect to('/')
        end
      else
        redirect to('/')
      end
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
        session[:player_id] = player.id
        return redirect to('/dashboard')
      else
        return slim :signup, :locals => {:errors => player.errors}
      end
    end

    get '/dashboard' do
      slim :dashboard
    end
 end
end

# vim:set ts=2 sw=2 et:
