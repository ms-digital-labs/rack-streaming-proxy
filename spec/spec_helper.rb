$:.unshift File.expand_path("../../lib", __FILE__)

require "rack/streaming_proxy"
require "rack/test"
require "servolux"
require "yaml"

RSpec.configure do |config|
end

