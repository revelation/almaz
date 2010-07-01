require 'rubygems'
gem 'rspec', '>= 1.2.8'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'almaz')
require 'base64'
require 'timecop'
require 'logger'
require 'date'

Spec::Runner.configure do |config|
  config.before(:all) {
    @db = Redis.new(:db => 15) #, :logger => Logger.new(STDOUT), :debug => true)
  }
  
  config.after(:each) {
    @db.flushdb
  }
  
  config.after(:all) {
    @db.quit
  }
end

def encode_credentials(username, password)
  "Basic " + Base64.encode64("#{username}:#{password}")
end


class ExampleSinatraApp < Sinatra::Base
  
  get '/awesome/controller' do
    'wooo hoo'
  end
  
end