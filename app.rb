# encoding: utf-8
require 'bundler/setup'
require 'sinatra/base'
require 'data_mapper'
require 'less'
require 'slim'
require 'coffee_script'

require_relative 'models.rb'

module Assassins
  class App < Sinatra::Base
    configure do
      enable :method_override
      enable :logging

      DataMapper::Logger.new($stderr, settings.development? ? :debug : :info)
      DataMapper.setup(:default, ENV['DATABASE_URL'])
      DataMapper::Model.raise_on_save_failure = true
      DataMapper.finalize
      DataMapper.auto_upgrade!
    end

    get '/' do
      slim :index
    end

    get '/login' do
      slim :login
    end

    get '/signup' do
      programs = Program.all
      slim :signup, :locals => {:programs => programs}
    end

    post '/signup' do
      if params.has_key? 'etower'
        room = 'E' + params['room']
      else
        room = params['room']
      end

      Player.create(:name => params['name'], :email => params['email'], :room_number => room, :program_id => params['program'])
      redirect to('/')
    end

    get '/leaderboard' do
      players = Player.all
      slim :leaderboard, :locals => {:players => players}
    end

    get '/main.css' do
      less :main, :views => 'styles'
    end

    get '/*' do
      slim :coming_soon
    end
  end
end

# vim:set ts=2 sw=2 et:
