# encoding: utf-8
require 'data_mapper'
require 'slim'

module Assassins
  class Player
    def send_verification (url)
      send_email('Please verify your identity',
                 "Secret words: #{self.secret}\n#{url}")
    end

    def send_email (subject, message)
      Email.send([{:email => self.email, :name => self.name}], subject, message)
    end

    def self.send_email_all (subject, message)
      to = []
      players = Player.all(:is_verified => true)
      players.each do |player|
        to << {:email => player.email, :name => player.name}
      end
      Email.send(to, subject, message)
    end

    def self.prune_inactive
      timeout = Time.now() - (60 * 60 * 24 * 3)
      timeout_notify = []
      target_notify = []
      Player.all(:is_verified => true, :is_alive => true).each do |player|
        if (player.last_activity < timeout)
          assassin = Assassins::Player.first(:target_id => player.id,
                                             :is_alive => true)
          $stderr.puts "PLAYER TIMED OUT: #{player.name}"

          player.is_alive = false
          player.save!
          timeout_notify << {:email => player.email, :name => player.name}

          assassin.target = player.target
          assassin.save!
          target_notify << assassin
        end
      end

      if !timeout_notify.empty?
        Email.send(timeout_notify, 'You have been removed from the game',
                   "You have been removed from the game because you have not made a kill in 3 days. Thanks for playing!")
      end

      target_notify.uniq.each do |assassin|
        assassin.set_target_notify(assassin.target)
      end
    end
  end

  class App < Sinatra::Base
    before do
      @player = nil
      if session.has_key? :player_id
        @player = Player.get session[:player_id]
        if @player.nil? || !@player.active?
          session.delete :player_id
        end
      end
    end

    set(:logged_in) do |val|
      condition {(!@player.nil? && @player.active?) == val}
    end

    get '/login' do
      slim :login
    end

    post '/login' do
      player = Player.first(:andrew_id => params.has_key?('andrew_id') ?
                                            params['andrew_id'].downcase : nil)
      if (player.nil?)
        return slim :login, :locals => {:errors =>
          ['Invalid Andrew ID. Please try again.']}
      end

      if (!player.active?)
        if (!player.is_verified)
          return redirect to('/signup/resend_verification')
        else
          return slim :login, :locals => {:errors =>
            ['You have been assassinated and your account made inactive. Thanks for playing!']}
        end
      end

      if (!(params.has_key?('secret') &&
            player.secret.casecmp(params['secret']) == 0))
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

    get '/signup', :game_started => false do
      slim :signup
    end

    post '/signup', :game_started => false do
      if (params.has_key?('andrew_id') && params['andrew_id'].index('@'))
        return slim :signup, :locals => {:errors =>
          ['Please enter only your Andrew ID, not your full email address.']};
      end

      player = Player.new(:name => params['name'],
                          :andrew_id => params.has_key?('andrew_id') ?
                                          params['andrew_id'].downcase : nil,
                          :floor_id => params['floor'],
                          :program_id => params['program'])
      player.generate_secret! 2
      if (player.save)
        player.send_verification(url("/signup/verify?aid=#{player.andrew_id}&nonce=#{player.verification_key}"))
        slim :signup_confirm
      else
        slim :signup, :locals => {:errors => player.errors.full_messages}
      end
    end

    get '/signup/resend_verification', :game_started => false do
      slim :resend_verification
    end

    post '/signup/resend_verification', :game_started => false do
      player = Player.first(:andrew_id => params['andrew_id'])
      if (player.nil?)
        return slim :resend_verification, :locals => {:errors =>
          ['Invalid Andrew ID']}
      end

      if (player.is_verified)
        return slim :resend_verification, :locals => {:errors =>
          ['That account has already been verified. You can log in using the form above.']}
      end

      player.verification_key = SecureRandom.uuid
      player.save!
      player.send_verification(url("/signup/verify?aid=#{player.andrew_id}&nonce=#{player.verification_key}"))
      slim :signup_confirm
    end

    get '/signup/verify', :game_started => false do
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

    get '/dashboard', :logged_in => true do
      slim :dashboard
    end

    post '/dashboard/assassinate', :logged_in => true do
      target = @player.target
      if (@player.failed_kill_attempts > 5)
        slim :dashboard, :locals => {:errors =>
          ["You have entered too many incorrect secret words. Please contact us to unlock your account."]}
      elsif (params.has_key?('target_secret') &&
               target.secret.casecmp(params['target_secret']) == 0)
        target.is_alive = false
        target.save!
        @player.kills += 1
        @player.failed_kill_attempts = 0
        @player.last_activity = Time.now
        @player.set_target_notify(target.target)
        @player.save!
        target.send_email('You were assassinated',
                          "You have been assassinated by #{@player.name}. Thanks for playing!")
        redirect to('/dashboard')
      else
        @player.failed_kill_attempts += 1
        @player.save!
        slim :dashboard, :locals => {:errors =>
          ["That isn't your target's secret. Please try again."]}
      end
    end

    get /^\/dashboard(\/.*)?$/, :logged_in => false do
      redirect to('/login')
    end
  end
end

# vim:set ts=2 sw=2 et:
