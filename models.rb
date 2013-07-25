# encoding: utf-8
require 'data_mapper'
require 'securerandom'

module Assassins
  class App < Sinatra::Base
    configure do
      DataMapper::Property.required(true)
    end
  end

  class Program
    include DataMapper::Resource

    property :id, Serial
    property :title, String
  end

  class Floor
    include DataMapper::Resource

    property :id, Serial
    property :name, String
    property :description, String
  end

  class Player
    include DataMapper::Resource

    property :id, Serial
    property :andrew_id, String, :unique => true,
      :messages => {
        :presence  => 'Andrew ID must not be blank',
        :is_unique => 'Andrew ID is already taken'
      }
    property :secret, String

    property :name, String
    belongs_to :floor
    belongs_to :program

    belongs_to :target, :model => 'Player', :required => false
    property :failed_kill_attempts, Integer, :default => 0
    property :is_alive, Boolean, :default => true
    property :kills, Integer, :default => 0
    property :last_activity, DateTime, :required => false

    property :verification_key, String,
             :default => lambda {|r,p| SecureRandom.uuid}
    property :is_verified, Boolean, :default => false

    def set_target_notify (target)
      self.target = target
      send_email('You have a new target!',
                 "Name: #{target.name}\nFloor: #{target.floor.description}\nProgram: #{target.program.title}\n\nPlease remember that the official rules are posted at http://www.cmu-assassins.tk/rules")
    end

    def generate_secret! (num_words)
      secret_words = []
      File.open('res/words') do |f|
        word_list = f.lines.to_a
        num_words.times do
          secret_words << word_list.sample.chomp.capitalize
        end
      end
      self.secret = secret_words.join(' ')
    end

    def email
      "#{self.andrew_id}@andrew.cmu.edu"
    end

    def active?
      self.is_verified && self.is_alive
    end
  end

  class Admin
    include DataMapper::Resource

    property :id, Serial
    property :username, String, :unique => true
    property :password, BCryptHash
  end

  class Game
    include DataMapper::Resource

    property :id, Serial
    property :start_time, DateTime, :required => false
  end
end

# vim:set ts=2 sw=2 et:
