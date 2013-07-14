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
    property :email, String, :format => :email_address, :unique => true
    property :room_number, String
    validates_format_of :room_number, :with => /^E?\d{3}$/
    before :save do
      self.room_number = self.room_number.upcase
    end

    property :failed_kills, Integer, :default => 0
    belongs_to :program
    belongs_to :target, :model => 'Player', :required => false
  end
end

# vim:set ts=2 sw=2 et:
