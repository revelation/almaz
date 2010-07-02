require 'rubygems'
require 'sinatra'
require 'redis'
require 'json'
require 'cgi'

class Almaz
  @@session_variable = 'session_id'
  @@redis_config = {:db => 0}
  @@expiry = 60 * 60 # 1 hour
  
  def self.session_variable=(val); @@session_variable = val; end
  def self.session_variable; @@session_variable; end 
  
  def self.redis_config=(new_config); @@redis_config = new_config; end
  def self.redis_config; @@redis_config; end
  
  def self.expiry=(new_expiry); @@expiry = new_expiry; end
  def self.expiry; @@expiry; end 
  
  class Capture
    def initialize(app)
      @app = app
      @r = Redis.new(Almaz.redis_config)
    end
    
    def call(env)      
      begin
        request_methods = Rack::Request.public_instance_methods(false).reject { |method_name| method_name =~ /[=\[]|content_length/ }.freeze
        request = Rack::Request.new(env)
        key = "almaz::#{Almaz.session_variable}::#{env['rack.session'][Almaz.session_variable]}"
        goodkeys = [ :request_method, :path_info, :referrer, :params, :ip]
        loggyfriend = {}
        request_methods.each do |method_name|
          loggyfriend[method_name] = request.send(method_name.to_sym) if goodkeys.include?(method_name.to_sym)
        end
        @r.rpush(key, loggyfriend.merge(:time => Time.now.to_s).to_json)
      rescue => e
        puts "ALMAZ ERROR: #{e}"
      end
      @app.call(env)
    end
  end
  
  class View < Sinatra::Base
    
    class << self
      def user(username, password)
        @@username = username
        @@password = password
      end
    end
    
    helpers do
      def protected!
        response['WWW-Authenticate'] = %(Basic realm="Stats") and \
        throw(:halt, [401, "Not authorized\n"]) and \
        return unless authorized?
      end

      def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [@@username, @@password]
      end
    end
    
    get '/almaz' do
      protected!
      content_type :json
      @r = Redis.new(Almaz.redis_config)
      @r.keys('*').to_json
    end
  
    get '/almaz/:id' do |id|
      protected!
      content_type :json
      @r = Redis.new(Almaz.redis_config)
      id = '' if id == 'noid'
      @r.lrange("almaz::#{Almaz.session_variable}::#{id}", 0, -1).map {|l| JSON.parse(l)}.to_json
    end
      
  end
end
