require 'rubygems'

require 'bcrypt'
require 'date'

require 'sinatra'
require 'haml'
require 'dm-core'
require 'do_sqlite3'

require File.dirname(__FILE__) + '/lib/authentication'

DataMapper.setup(:default, 'sqlite3://overstolen.db')

HOST_URL = 'http://overstolen.heroku.com'

module OverStolen
  class Key
    include DataMapper::Resource

    property :id,             Serial
    property :client,         String
    property :encrypted_key,  String
    property :current_seed,   String
    property :valid_until,    DateTime

    def generate_key
      return false if valid_until < Date.today
      self.encrypted_key = BCrypt::Password.create(seed)
      self.valid_until = Date.today
      true
    end

    def seed

    end

  end
  DataMapper.auto_upgrade!
end

module OverStolen
  class App < Sinatra::Base
    register Sinatra::Warden

    helpers do
      def absolute_url(suffix = nil)
        port_part = case request.scheme
                    when "http"
                      request.port == 80 ? "" : ":#{request.port}"
                    when "https"
                      request.port == 443 ? "" : ":#{request.port}"
                    end
          "#{request.scheme}://#{request.host}#{port_part}#{suffix}"
      end
    end

    enable :auth_use_oauth
    set :auth_oauth_authorize_url, lambda { Account.authorize_url }

    get '/:client_name/salt' do |client_name|
      @key = Key.first(:client => client_name)
      "#{@key.current_seed}"
    end

    get '/:client_name' do |client_name|
      @key = Key.first(:client => client_name)
      @key.nil? ? "invalid!" : "#{@key.encrypted_key}"
    end

    get '/' do
      @keys = Key.all
      haml :index
    end

  end
end
