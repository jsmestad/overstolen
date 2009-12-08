require 'rubygems'

require 'bcrypt'
require 'date'

require 'sinatra'
require 'dm-core'
require 'do_sqlite3'

DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3://my.db')

HOST_URL = 'http://overstolen.heroku.com'

module OverStolen
  class Key
    include DataMapper::Resource
    
    property :id,             Serial
    property :client,         String
    property :encrypted_key,  String
    property :valid_until,    DateTime
    
    def generate_key(seed=Date.today.to_s)
      return false if valid_until < Date.today
      self.encrypted_key = BCrypt::Password.create(seed)
      self.valid_until = Date.today
      true
    end
    
  end
  DataMapper.auto_migrate!
end

module OverStolen
  class App < Sinatra::Base
    get '/:client_name' do |client_name|
      @key = Key.first(:client => client_name)
      @key.nil? ? "invalid!" : "#{@key.encrypted_key}"
    end
  end
end