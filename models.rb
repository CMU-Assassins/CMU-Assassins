# encoding: utf-8
require 'data_mapper'
require 'securerandom'

module Assassins
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
    property :andrew_id, String, :unique => true
    property :secret, String

    property :name, String
    belongs_to :floor
    belongs_to :program

    belongs_to :target, :model => 'Player', :required => false
    property :failed_kill_attempts, Integer, :default => 0
    property :is_alive, Boolean, :default => true
    property :kills, Integer, :default => 0

    property :verification_key, String
    before :create do
      self.verification_key = SecureRandom.uuid
    end
    property :is_verified, Boolean, :default => false

    def send_verification (mailer, url)
      message = {
        :subject => 'Please verify your identity',
        :from_name => 'CMU Assassins',
        :text => "Secret words: #{self.secret}\n#{url}",
        :to => [
          {
            :email => "#{self.andrew_id}@andrew.cmu.edu",
            :name => self.name
          }
        ],
        :from_email => 'donotreply@cmu-assassins.tk'
      }
      $stderr.puts mailer.messages.send(message)
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
  end
end

# vim:set ts=2 sw=2 et:
