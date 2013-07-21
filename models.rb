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

    property :verification_key, String,
             :default => lambda {|r,p| SecureRandom.uuid}
    property :is_verified, Boolean, :default => false

    def set_target_notify (target)
      self.target = target
      self.save!
      # TODO: Send notification email.
    end

    def send_verification (mailer, url)
      message = {
        :subject => 'Please verify your identity',
        :from_name => 'CMU Assassins',
        :text => "Secret words: #{self.secret}\n#{url}",
        :to => [
          {
            :email => self.email,
            :name => self.name
          }
        ],
        :from_email => 'donotreply@cmu-assassins.tk'
      }
      if !mailer.nil?
        $stderr.puts mailer.messages.send(message)
      else
        $stderr.puts "Sending verification for #{self.andrew_id}"
        $stderr.puts "Message body: #{message[:text]}"
      end
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

    def active?
      self.is_verified && self.is_alive
    end

    def email
      "#{self.andrew_id}@andrew.cmu.edu"
    end
  end

  class Admin
    include DataMapper::Resource

    property :id, Serial
    property :username, String, :unique => true
    property :password, BCryptHash
  end
end

# vim:set ts=2 sw=2 et:
