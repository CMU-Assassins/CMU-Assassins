# encoding: utf-8
require 'data_mapper'

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
    property :name, String
    property :andrew_id, String, :unique => true
    belongs_to :floor
    property :failed_kill_attempts, Integer, :default => 0
    property :secret, String

    belongs_to :program
    belongs_to :target, :model => 'Player', :required => false

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
  end
end

# vim:set ts=2 sw=2 et:
