require 'redis'
require 'json'

class Almaz
  @config = { :redis => {:db => 0},
              :session_variable => :user,
              :max_list_size => 100,
              :capture_keys => [:request_method, :path_info, :referrer, :params, :ip]
            }
  
  def self.config
    @config
  end
  
  class Capture
    def initialize(app)
      @app = app
      @r = Redis.new(Almaz.config[:redis])
    end
    
    def call(env)
      begin
        request = Rack::Request.new(env)
        key = "almaz::#{Almaz.config[:session_variable]}::#{env['rack.session'][Almaz.config[:session_variable]]}"
        @r.rpush(key, capture_keys(request).to_json)
        @r.ltrim(key, 0, Almaz.config[:max_list_size] - 1)
      rescue => e
        puts "ALMAZ ERROR: #{e}"
      end
      
      @app.call(env)
    end

    def capture_keys(request)
      captured = {}
      Rack::Request.public_instance_methods(false).each do |request_method|
        captured[request_method] = request.send(request_method.to_sym) if Almaz.config[:capture_keys].include?(request_method.to_sym)
      end
      captured.merge!(:time => Time.now.to_s, :user_agent => request.env["HTTP_USER_AGENT"])
      captured
    end
  end
end
