class Streamer
  include Rack::Utils

  def initialize(sleep=0.05)
    @sleep = sleep
    @strings = 5.times.collect {|n| "~~~~~ #{n} ~~~~~\n" }
  end

  def call(env)
    req = Rack::Request.new(env)
    headers = {"Content-Type" => "text/plain"}
    [200, headers, self.dup]
  end

  def each
    @strings.each do |chunk|
      yield chunk
      sleep @sleep
    end
  end
end

map "/" do
  run lambda { |env| [200, {"Content-Type" => "text/plain"}, ["ALL GOOD"]] }
end

map "/stream" do
  run Streamer.new
end

map "/slow_stream" do
  run Streamer.new(0.5)
end

map "/env" do
  run lambda { |env|
    req = Rack::Request.new(env)
    req.POST # modifies env inplace to include "rack.request.form_vars" key
    body = env.map{|k,v| "#{k}: #{v}" }.join("\n")
    [200, {"Content-Type" => "text/plain"}, [body]] }
end

map "/boom" do
  run lambda { |env| [500, {"Content-Type" => "text/plain"}, ["kaboom!"]] }
end

