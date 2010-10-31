# ReReplay

ReReplay is for replaying production traffic (or any scripted traffic pattern, for that matter).  You simply input a list of URLs that you want ReReplay to hit, and their associated times to make the request, and run it.

There are a couple other main features as well.  You can provide Request Monitors to ReReplay -- these are executed before and/or after every request.  There are also Periodic Monitors, which execute on regular intervals (for monitoring memory usage, or something).  Lastly, you can provide a rampup strategy as well.  For example, you could start out making requests at the "regular" rate, and by the end of the run be making requests at double the rate presribed in the original input.

# Examples

(It's assumed you've already require'd "rereplay")

## Simple
	input = [
		[0, :get, "http://www.google.com/"],
		[0.5, :get, "http://www.microsoft.com/"],
		[0.9, :get, "http://www.amazon.com/"]
	]
	r = ReReplay::Runner.new(input)
	r.run
	# and done!
	# this executes an HTTP GET against the provided URL at the associated time

Of course, this doesn't actually track any output, so...let's monitor the request time using the request_time_monitor:

## Request Monitor
    require "rereplay/monitors"
    input = [ ...same as in Simple... ]
    mon = ReReplay::RequestTimeMonitor.new
    r = ReReplay::Runner.new(input)
    r.request_monitors << mon
    r.run
    puts mon.results.inspect

This will print out the results from the RequestTimeMonitor instance, which includes the url, the duration of the request, and its scheduled start time.

# Monitors

If you want to do something more than simply execute HTTP requests, you'll need monitors to interact (in realtime) with your data.

## Request Monitors

Request monitors monitor indivual requests -- they're simple Ruby objects that implement part or all of the RequestMonitor interface, and they execute before and/or after every request.  The interface looks like this:

	class SampleRequestMonitor
		# executes as the request is starting
		# optional
		def start(request) # => nil
			# see below for what request is
			# ...
		end
		
		# executes just after the request has finished
		# optional
		def finish(request) # => nil
			# request is same as start here, but with #finish and #status properties
			# ...
		end
		
		# results is the standard way to get the main output from a monitor
		# optional, purely convention
		def results # => any return value
			# ...
		end
	end
	
	# The request object has the following getters:
	# 	#url => complete url as String used for the request
	# 	#scheduled_start => time since start (as Float) that this request should have been made
	# 	#actual_start => time since start that request was actually executed
	# 	#index => position in input that request had; first request has index 0, second request has 1, etc.
	# 	#http_method => http method that should be used to execute the request (lowercase symbol, i.e. :get)
	# 	#finish => time since start that request finished executing (only available if request has finished)
	# 	#status => HTTP response code as an integer, or if a timeout occurred, as :timeout
	
[RequestTimeMonitor](ReReplay/blob/master/lib/rereplay/monitors/request_time_monitor.rb) is an example of a Request Monitor.

## Periodic Monitors

Periodic monitors are monitors that, well, run *periodically* -- out of sync with individual requests, at an arbitrary (but fixed) interval.  Here's what it the periodic monitor spec looks like:

	class SamplePeriodicMonitor
		# main method that executes at regular intervals
		# required
		def tick(time_since_start) # => nil
			# ...
		end
		
		# same as request monitor
		# optional, purely convention
		def results # => whatever
			# ...
		end
		
		# interval (as an fixnum or float) in seconds at which #tick will execute.  Only read once.
		# optional (defaults to 5 [seconds])
		def interval
			# you may wish to implement this as @interval = 2 w/ attr_reader :interval in your constructor
		end
	end
	
[MemoryMonitor](ReReplay/blob/master/lib/rereplay/monitors/memory_monitor.rb) is an example of a Periodic Monitor.
	
## Using monitors

ReReplay has a few sample monitors built in -- to load these, require "rereplay/monitors".  To use monitors in your Runner instance, simply shift on an instance:

	require 'rereplay/monitors'
	mon = ReReplay::VerboseMonitor.new
	periodic_monitor = ReReplay
	r = ReReplay::Runner.new(...)
	r.request_monitors << mon
	r.periodic_monitors << periodic_monitor
	r.run
	# poke around with mon.results and periodic_monitor.results
	
# Specs

Specs have more examples and probably more up-to-date, too.  They're fairly simple -- start with basic.rb.  To run them yourself, use Bundler to `bundle install` first, modify .infinity_test to exclude (or include) the Ruby implementations you want to test, then `bundle exec infinity_test` away.

# Cross-Ruby Interoperability

## Ruby 1.8

Ruby 1.8 works, but it's not very...prompt.  If you schedule multiple requests close together (under 0.1s), Ruby 1.8 will quickly fall behind (missing scheduled times by hundreds of milliseconds, potentially).  Not recommended.  I've tested with Ruby 1.8.7-p302.

## Ruby 1.9

Ruby 1.9 works great.  Even when scheduling requests close together (on the order of ~0.001 seconds apart) Ruby 1.9 doesn't miss a beat -- scheduled times are typically missed by about a quarter millisecond, regardless of request density.  I've tested Ruby 1.9.2-p0.

## JRuby

JRuby is the same story Ruby 1.9 -- requests start times are missed by less than a millisecond, typically.  Tested with JRuby 1.5.3.

## Others

Not that anyone is likely to use the other Ruby engines for running a script like this, but they're included for sake of completeness.  And I might as well document them, since I'm running my tests against them.

### Ruby Edge

This is the ruby-head that rvm can install for you.  It runs the tests just fine at time of writing, at about the same speed as Ruby 1.9.2-p0.

### Ruby Enterprise Edition

Same as Ruby 1.8.  Tested version was 1.8.7-2010.02.

### Rubinius

Usually produces error messages when tests are run in `vm/util/thread.hpp`, which I imagine is partially due to my dependence on monitors and condition variables.  Even so, the tests all technically pass.  Couldn't get Rubinius to work with Sinatra at all, so didn't test performance.  Tested version was 1.1.0-20100923.

# More

More you ask??  Well, that's what the more/ directory is for.

## Web

Fun little app that executes some requests and shows them in a website in realtime.  Uses Sinatra and sqlite and tested with Ruby 1.8, Ruby 1.9, and JRuby.  Run using `cd more/web && bundle install && bundle exec ruby web.rb`.  If you want to see for yourself how well your Ruby implementation is performing, this is the easiest, albeit qualitative, way to do it.

# License

Licensed under the permissive MIT license, provided in the LICENSE file.  Not required, but I'd appreciate it if you sent me a GitHub message letting me know what your experience with the tool is, and if you're at the liberty to, tell me how you're using it.  I'm curious!
