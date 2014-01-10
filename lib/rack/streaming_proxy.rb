require "rack"
require "net/http"
require "uri"

module Rack
  class StreamingProxy
    VERSION = '1.0.3'
    ProxyError = Class.new(RuntimeError)

    # The block provided to the initializer is given a Rack::Request
    # and should return:
    #
    #   * nil/false to skip the proxy and continue down the stack
    #   * a complete uri (with query string if applicable) to proxy to
    #
    # E.g.
    #
    #   use Rack::StreamingProxy do |req|
    #     if req.path.start_with?("/search")
    #       "http://some_other_service/search?#{req.query}"
    #     end
    #   end
    #
    # Most headers, request body, and HTTP method are preserved.
    def initialize(app, &block)
      @request_uri = block
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)
      if uri = request_uri.call(req)
        proxy_request_to(req, uri)
      else
        app.call(env)
      end
    end

  protected
    def proxy_request_to(req, uri)
      ProxyRequest.call(req, uri)
    rescue => e
      msg = "Proxy error when proxying to #{uri}: #{e.class}: #{e.message}"
      req.env["rack.errors"].puts msg
      req.env["rack.errors"].puts e.backtrace.map { |l| "\t" + l }
      req.env["rack.errors"].flush
      raise ProxyError, msg
    end

    attr_reader :request_uri, :app
  end
end

require "rack/streaming_proxy/proxy_request"
