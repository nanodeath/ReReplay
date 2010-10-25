# ReReplay

ReReplay is for replaying production traffic (or any scripted traffic pattern, for that matter).  You simply input a list of URLs that you want ReReplay to hit, and their associated times to make the request, and run it.

There are a couple other main features as well.  You can provide Request Monitors to ReReplay -- these are executed before and/or after every request.  There are also Periodic Monitors, which execute on regular intervals (for monitoring memory usage, or something).  Lastly, you can provide a rampup strategy as well.  For example, you could start out making requests at the "regular" rate, and by the end of the run be making requests at double the rate presribed in the original input.

# Examples

(It's assumed you've already require'd "rereplay")

## Simple
    input = [
    	[0, 	:get, "http://www.google.com/"],
    	[0.5, :get, "http://www.microsoft.com/"],
    	[0.9, :get, "http://www.amazon.com/"]
    ]
    r = ReReplay.new(input)
    r.run
    # and done!    

Of course, this doesn't actually track any input, so...let's monitor the request time using the request_time_monitor:

## Request Monitor
    require "rereplay/monitors/request_time_monitor"
    input = [same as in Simple]
    mon = RequestTimeMonitor.new
    r = ReReplay.new(input)
    r.request_monitors << mon
    r.run
    puts mon.results.inspect

This will print out the results from the RequestTimeMonitor instance, which includes the url, the duration of the request, and its scheduled start time.

## Specs

Specs have more examples and probably more up-to-date, too.  They're fairly simple -- start with basic.rb.

# License

Licensed under the permissive MIT license, provided in the LICENSE file.
