$:.unshift File.expand_path("../../lib", __FILE__)

require "rack/streaming_proxy"
require "rack/test"
require "pry"

module WaitForServer
  def wait_for_server(port)
    Timeout.timeout(2) do
      wait_for_server_indefinately(port)
    end
  end

  def wait_for_server_indefinately(port)
    Net::HTTP.get_response("localhost", "/", port)
  rescue Errno::ECONNREFUSED
    sleep 0.01
    retry
  end
end

require "rack/handler/puma"
module Rack::Handler::Puma
  def self.puts(*args)
  end
end

RSpec.configure do |config|
  config.include WaitForServer
end

