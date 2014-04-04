## DESCRIPTION:
Streaming proxy for Rack, the rainbows to Rack::Proxy's unicorn.

## FEATURES:
Provides a transparent streaming proxy to be used as rack middleware.

* Streams the response from the downstream server to minimize memory usage
* Uses fibers, which is seriously cool
* Handles chunked encoding if used
* Uses fibers
* Proxies ALL OF THE THINGS
* Uses fibers

## SYNOPSIS:

```ruby
require "rack/streaming_proxy"

use Rack::StreamingProxy do |request|
  # inside the request block, return the full URI to redirect the request to,
  # or nil/false if the request should continue on down the middleware stack.
  if request.path.start_with?("/proxy")
    "http://another_server#{request.path}"
  end
end
```

## LICENSE:

(The MIT License)

Copyright (c) 2009 Nathan Witmer

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
