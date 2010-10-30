require 'spec_helper'

describe ReReplay, "periodic monitors" do
	it "should work" do
		mem_monitor = ReReplay::MemoryMonitor.new
		mem_monitor.interval = 0.2
		
		input = generate_input(3, :interval => 0.25)
		r = ReReplay::Runner.new(input)
		r.periodic_monitors << mem_monitor
		
		r.run
		validate_input(3)
		mem_monitor.results.length.should == 4
	end
end

describe ReReplay, "request monitors" do
	it "should work" do
		req_mon = ReReplay::RequestTimeMonitor.new
		delay_mon = ReReplay::DelayMonitor.new
		
		input = generate_input(3, :interval => 0.25)
		r = ReReplay::Runner.new(input)
		r.request_monitors << req_mon << delay_mon

		r.run
		validate_input(3)
		req_mon.results.length.should == 3
		delay_mon.results.length.should == 3
	end
	
	describe ReReplay::VerboseMonitor do
		it "should be verbose" do
			input = generate_input(3, :interval => 0.25)
			r = ReReplay::Runner.new(input)
			r.request_monitors << ReReplay::VerboseMonitor.new
			expected = Regexp.new(<<EOF, Regexp::MULTILINE)
started request 0:\\(http://google.com/\\) at [\\d\\.]+
 - finished request 0, status 200
started request 1:\\(http://microsoft.com/\\) at [\\d\\.]+
 - finished request 1, status 200
started request 2:\\(http://amazon.com/\\) at [\\d\\.]+
 - finished request 2, status 200
EOF
			capture_stdout { r.run }.should match(expected)
			validate_input(3)
		end
	end
end

