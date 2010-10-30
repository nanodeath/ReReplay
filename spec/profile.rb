require 'spec_helper'

describe ReReplay, "profile options" do
	it "respects 'run_for' parameter" do
		input = generate_input(3, :interval => 1)
		r = ReReplay::Runner.new(input)
		profile = {
			:run_for => 1
		}
		r.profile = profile
		
		# normally this would run for the full 4 seconds, but with run_for fixed at 2,
		# it will stop then
		lambda { r.run }.should take_between(1.seconds).and(1.1.seconds)
		validate_input(1)
	end
	
	it "respects 'when_input_consumed' parameter when :stop" do
		input = generate_input(3, :interval => 0.5)
		r = ReReplay::Runner.new(input)
		profile = {
			:run_for => 10,
			:when_input_consumed => :stop
		}
		r.profile = profile
		
		lambda { r.run }.should take_between(1.5.seconds).and(1.7.seconds)
		validate_input(3)
	end
	
	it "respects 'when_input_consumed' parameter when :loop" do
		input = generate_input(1, :interval => 0.5)
		r = ReReplay::Runner.new(input)
		profile = {
			:run_for => 1.1,
			:when_input_consumed => :loop
		}
		r.profile = profile
		req_mon = ReReplay::RequestTimeMonitor.new
		r.request_monitors << req_mon
		
		# normally this would take 1.5 seconds with :stop, but we're forcing it to loop and take 2 seconds
		lambda { r.run }.should take_between(1.1.seconds).and(1.2.seconds)
		req_mon.results.length.should == 2
		validate_input(1, 2)
	end
	
	# eh, this isn't that good a test because WebMock causes #to_timeout requests to timeout immediately
	# but it tests that timeout works
	it "works with timeouts" do
		input = generate_input(1, :interval => 0.25, :timeout => true)
		r = ReReplay::Runner.new(input)
		profile = {
			:timeout => 10
		}
		r.profile = profile
		r.request_monitors << ReReplay::TimeoutFailer.new
		
		lambda { lambda { r.run }.should raise_error(StandardError, /TimeoutFailer/) }.should take_between(0.25.seconds).and(0.5.seconds)
		validate_input(1)
	end

end
