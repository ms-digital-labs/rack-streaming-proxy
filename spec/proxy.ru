$:.unshift File.expand_path("../../lib", __FILE__)
require "rack/streaming_proxy"

use Rack::Lint
# use Rack::CommonLogger
use Rack::StreamingProxy do |req|
  "http://localhost:4321#{req.path}"
end
run lambda { |env| [200, {}, ["should never get here..."]]}
