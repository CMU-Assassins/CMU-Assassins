# encoding: utf-8
require 'data_mapper'
require 'slim'

module Assassins
  class App < Sinatra::Base
    helpers do
      def game_started?
        false
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
