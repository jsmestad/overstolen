gem 'warden', '~> 0.5.3'
require 'warden'
require 'sinatra_warden'
require 'oauth'
require 'dm-core'

Warden::Strategies.add(:twitter) do
  def authenticate!
    if params.include?('oauth_token') && credentials.authenticate!(params['oauth_token'])
      session.delete(:credential)
      success!(credentials)
    end
    redirect!(credentials.authentication_url)
  end

  def credentials
    @credentials ||= Credential.get(session[:credential] ||= Credential.create.id)
  end
end

Warden::Manager.serialize_into_session {|cred| cred.to_s }
Warden::Manager.serialize_from_session {|id| Account.get(id) }

class Account
  include DataMapper::Resource

  CONSUMER_KEY    = '7U73FGrbKe5WbzjJU3lQ'
  CONSUMER_SECRET = 'VDASUX4VsMPSFoqk298QluBsSk2yL6aY7dezpxZD8m0'

  property :id,             Serial
  property :access_token,   String
  property :access_secret,  String
  property :request_token,  String
  property :request_secret, String

  def request
    @request ||= if request_token.nil? || request_secret.nil?
      request = consumer.get_request_token
      request if self.update(:request_token => request.token, :request_secret => request.secret)
    else
      OAuth::RequestToken.new(consumer, request_token, request_secret)
    end
  end

  def self.authorize_url(options={})
    consumer.get_request_token(options).authorize_url
  end

  def access
    @access ||= if access_token.nil? || access_secret.nil?
      access = request.get_access_token
      access if update(:access_token => access.token, :access_secret => access.secret)
    else
      OAuth::AccessToken.new(consumer, access_token, access_secret)
    end
  end

private

  def self.consumer
    OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, :site => 'http://twitter.com')
  end

end
