class Rack::StreamingProxy::ProxyRequest
  include Rack::Utils

  FORWARDABLE_HEADERS= %w[
    Accept
    Accept-Encoding
    Accept-Charset
    Authorization
    Cookie
    Referer
    User-Agent
    X-Requested-With
  ]

  def self.call(request, uri)
    new(request, uri).call
  end

  def call
    [fiber.resume, fiber.resume, fiber_enum(fiber)]
  end

protected
  attr_reader :request, :uri

  def initialize(request, uri)
    @request, @uri = request, URI.parse(uri)
  end

  def fiber
    @fiber ||= Fiber.new{ process_proxy_request }
  end

  def process_proxy_request
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(proxy_request) do |response|
        Fiber.yield response.code.to_i
        Fiber.yield extract_headers(response)
        response.read_body{ |chunk| Fiber.yield chunk }
      end
      nil
    end
  rescue => e
    error_response(e)
  end

  def build_proxy_request
    method = request.request_method.downcase
    method[0..0] = method[0..0].upcase

    proxy_request = Net::HTTP.const_get(method).new("#{uri.path}#{"?" if uri.query}#{uri.query}")

    if proxy_request.request_body_permitted? and request.body
      proxy_request.body_stream = request.body
      proxy_request.content_length = request.content_length
      proxy_request.content_type = request.content_type
    end

    FORWARDABLE_HEADERS.each do |header|
      key = "HTTP_#{header.upcase.gsub('-', '_')}"
      proxy_request[header] = request.env[key] if request.env[key]
    end

    proxy_request["X-Forwarded-For"] = [
      *request.env["X-Forwarded-For"].to_s.split(/, +/),
      request.env["REMOTE_ADDR"]
    ].join(", ")

    proxy_request
  end

  def proxy_request
    @proxy_request ||= build_proxy_request
  end

  def fiber_enum(fiber)
    Enumerator.new{ |out|
      while v = fiber.resume
        out.yield v
      end
    }
  end

  def extract_headers(response)
    response.each_header do |k,v|
      p k => v
    end
    headers = response.each_header.reject{|k,v|
      k.downcase == "transfer-encoding"
    }
    Hash[headers]
  end

  def error_response(e)
    Fiber.yield 503
    Fiber.yield "Content-Type" => "text/plain"
    Fiber.yield "Exception while handling request:\n"
    Fiber.yield e.class.to_s
    Fiber.yield "\n"
    Fiber.yield e.message
    Fiber.yield "\n"
    Fiber.yield e.backtrace.join("\n")
  end
end
