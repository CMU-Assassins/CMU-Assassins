# encoding: utf-8
require 'data_mapper'
require 'slim'

module Assassins
  class App < Sinatra::Base
    before do
      @game = Game.first
      if @game.nil?
        @game = Game.new
        @game.save
      end
    end

    set(:game_started) do |val|
      condition {(game_started? == val)}
    end

    helpers do
      def game_started?
        !@game.start_time.nil? && Time.now >= @game.start_time
      end
    end

    get '/leaderboard' do
      if game_started?
        slim :leaderboard
      else
        redirect to('/')
      end
    end

    def check_timeout
      timeout = Time.now() - (60 * 60 * 24 * 3)
      Assassins::Player.all(:is_alive => true).each do |player|
        if (player.last_activity < timeout)
          assassin = Assassins::Player.first(:target_id => player.id, :is_alive => true)
          $stderr.puts "PLAYER TIMED OUT: #{player.name}"
          target = player.target
          player.is_alive = false
          player.save!
          assassin.set_target_notify(settings.mailer, target)
          assassin.save!

          player.send_email(settings.mailer, 'You have been removed from the game',
                              "You have been removed from the game due to not getting a kill in 3 days. Thanks for playing!")
        end
      end
    end
  end
end

# vim:set ts=2 sw=2 et:
