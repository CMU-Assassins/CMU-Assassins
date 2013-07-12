# encoding: utf-8
require 'data_mapper'

module Assassins
  class Program
    include DataMapper::Resource

    property :id, Serial
    property :title, String
  end

  class Player
    include DataMapper::Resource

    property :id, Serial
    property :name, String
    property :andrew_id, String
    property :room_number, String
    before :save do
      room_number = room_number.upcase
    end

    validates_format_of :room_number, :with => /^E?\d{3}$/
    property :email, String, :required => false, :format => :email
    def email
      super.empty? ? "#{andrew_ID}@andrew.cmu.edu" : super
    end

    property :failed_kills, Integer, :default => 0
    belongs_to :program
    belongs_to :target, :model => 'Player'
  end
end

# vim:set ts=2 sw=2 et:
