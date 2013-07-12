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
      slim :teaser
    end

    get '/*' do
      slim :coming_soon
    end
  end
end

# vim:set ts=2 sw=2 et:
