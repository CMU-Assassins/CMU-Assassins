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
  end
end

# vim:set ts=2 sw=2 et:
