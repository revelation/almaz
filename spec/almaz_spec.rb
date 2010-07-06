require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'rack/test'

describe Almaz do
  before(:each) do
    Almaz.config[:redis] = {:db => 15}
  end

  describe Almaz::Capture do
    include Rack::Test::Methods
 
    def app
      use Rack::Session::Cookie, :key => '_max_project_session'
      use Almaz::Capture
      Sinatra::Application
    end
  
    describe "with session's user id" do
  
      before(:each) do
        session_info = {:user => 1}
        rack_mock_session.set_cookie("_max_project_session=#{[Marshal.dump(session_info)].pack("m*")}")
      end

      it "should capture the request path under the session_variable" do
        get '/awesome/controller'
        @db.lrange('almaz::user::1',0,-1).first.should include('/awesome/controller')
      end
    
      it "should capture the request query params under the session_variable" do
        get '/awesome/controller?whos=yourdaddy&what=doeshedo'
        logged_request = @db.lrange('almaz::user::1',0,-1).first
        JSON.parse(logged_request)['params'].should == {"whos"=>"yourdaddy", "what"=>"doeshedo"}
      end

      it "should capture the request method params under the session_variable" do
        get '/awesome/controller'
        @db.lrange('almaz::user::1',0,-1).first.should include('GET')
      end

      it "should capture the post params under the session_variable" do
        post '/awesome/controller', :didyouknow => 'thatyouremyhero'
        logged_request = @db.lrange('almaz::user::1',0,-1).first
        JSON.parse(logged_request)['params'].should == {"didyouknow"=>"thatyouremyhero"}
      end
      
      it "should record a timestamp on each request" do
        Timecop.freeze(Date.today + 30) do        
          post '/awesome/controller', :didyouknow => 'thatyouremyhero'
          @db.lrange('almaz::user::1',0,-1).first.should include(Time.now.to_s)
        end
      end
      
      it "should only store the most recent requests up to the maximum configured length" do
        max_size = Almaz.config[:max_list_size] = 10
        post '/awesome/controller', :didyouknow => 'thisshouldbedeleted'
        max_size.times {|taco| post '/awesome/controller', :didyouknow => 'thatyouremyhero'}
        @db.llen('almaz::user::1').should == max_size
        logged_request = @db.lrange('almaz::user::1', -1, -1).first
        JSON.parse(logged_request)['params'].should_not == {"didyouknow"=>"thisshouldbedeleted"}
      end
    end
  end
end