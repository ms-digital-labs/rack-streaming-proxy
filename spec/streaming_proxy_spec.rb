require File.join(File.dirname(__FILE__), %w[spec_helper])

describe Rack::StreamingProxy do
  include Rack::Test::Methods

  APP_PORT = 4321 # hardcoded in proxy.ru as well!
  PROXY_PORT = 4322

  def app
    @app ||= Rack::Builder.new do
      use Rack::Lint
      use Rack::Chunked
      use Rack::StreamingProxy do |req|
        unless req.path.start_with?("/not_proxied")
          url = "http://localhost:#{APP_PORT}#{req.path}"
          url << "?#{req.query_string}" unless req.query_string.empty?
          # STDERR.puts "PROXYING to #{url}"
          url
        end
      end
      run Rack::Builder.app{
        use Rack::ContentLength
        run lambda { |env|
          raise "app error" if env["PATH_INFO"] =~ /boom/
          [200, {"Content-Type" => "text/plain"}, ["not proxied"]]
        }
      }
    end
  end

  def app_path
    File.expand_path("../app.ru", __FILE__)
  end

  def proxy_path
    File.expand_path("../proxy.ru", __FILE__)
  end

  before(:all) do
    @app_server = Servolux::Child.new(
      :command => "rackup #{app_path} -s puma -p #{APP_PORT} ",
      :timeout => 30,
      :suspend => 0.25
    )
    @app_server.start
    sleep 2
  end

  after(:all) do
    @app_server.stop
    @app_server.wait
  end


  def with_proxy_server
    @proxy_server = Servolux::Child.new(
      :command => "rackup #{proxy_path} -s puma -p #{PROXY_PORT} ",
      :timeout => 10,
      :suspend => 0.25
    )
    @proxy_server.start
    sleep 2
    yield
  ensure
    @proxy_server.stop
    @proxy_server.wait
  end

  it "passes through to the rest of the stack if block returns false" do
    get "/not_proxied"
    last_response.should be_ok
    last_response.body.should == "not proxied"
  end

  it "proxies a request back to the app server" do
    get "/"
    last_response.should be_ok
    last_response.body.should == "ALL GOOD"
  end

  it "uses chunked encoding when the app server send data that way" do
    get "/stream"
    last_response.should be_ok
    last_response.headers["Transfer-Encoding"].should == "chunked"
    last_response.body.should =~ /^~~~~~ 0 ~~~~~/
  end

  # this is the most critical spec: it makes sure things are actually streamed, not buffered
  it "streams data from the app server to the client" do
    with_proxy_server do
      times = []
      Net::HTTP.start("localhost", PROXY_PORT) do |http|
        http.request_get("/slow_stream") do |response|
          response.read_body do |chunk|
            times << Time.now.to_i
          end
        end
      end

      (times.last - times.first).should >= 2
    end
  end

  it "handles POST, PUT, and DELETE methods" do
    post "/env"
    last_response.should be_ok
    last_response.body.should =~ /REQUEST_METHOD: POST/
    put "/env"
    last_response.should be_ok
    last_response.body.should =~ /REQUEST_METHOD: PUT/
    delete "/env"
    last_response.should be_ok
    last_response.body.should =~ /REQUEST_METHOD: DELETE/
  end

  it "sets a X-Forwarded-For header" do
    post "/env"
    last_response.should =~ /HTTP_X_FORWARDED_FOR: 127.0.0.1/
  end

  it "preserves the post body" do
    post "/env", "foo" => "bar"
    last_response.body.should =~ /rack.request.form_vars: foo=bar/
  end

  it "raises a Rack::Proxy::StreamingProxy error when something goes wrong" do
    Rack::StreamingProxy::ProxyRequest.should_receive(:new).and_raise(RuntimeError.new("kaboom"))
    lambda { get "/" }.should raise_error(Rack::StreamingProxy::ProxyError, /proxy error.*kaboom/i)
  end

  it "does not raise a Rack::Proxy error if the app itself raises something" do
    lambda { get "/not_proxied/boom" }.should raise_error(RuntimeError, /app error/)
  end

  it "preserves cookies" do
    set_cookie "foo"
    post "/env"
    last_response.body.should include("HTTP_COOKIE: foo")
  end

  it "preserves authentication info" do
    basic_authorize "admin", "secret"
    post "/env"
    last_response.body.should include("HTTP_AUTHORIZATION: Basic YWRtaW46c2VjcmV0")
  end

end

