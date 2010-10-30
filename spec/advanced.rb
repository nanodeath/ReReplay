require 'spec_helper'

describe ReReplay, "advanced functions" do
	it "should support linear rampup" do
		input = generate_input(10, :start_at_0 => true)
		
		r = ReReplay::Runner.new(input)
		profile = {
			:rampup => [1.0, 2.0]
		}
		r.profile = profile
		lambda { r.run }.should take_between(1.65.seconds).and(1.8.seconds)
		validate_input(10)
	end
	
	it "should support linear rampup from <1 to >1" do
		input = generate_input(10, :start_at_0 => true)
		
		r = ReReplay::Runner.new(input)
		profile = {
			:rampup => [0.5, 2]
		}
		r.profile = profile
		lambda { r.run }.should take_between(2.05.seconds).and(2.2.seconds)
		validate_input(10)
	end
	
	it "should play nicely with run_for and :loop" do
		input = generate_input(10, :start_at_0 => true)
		
		r = ReReplay::Runner.new(input)
		profile = {
			:rampup => [0.5, 2],
			:run_for => 2,
			:when_input_consumed => :loop
		}
		r.profile = profile
		lambda { r.run }.should take_between(3.seconds).and(3.1.seconds)
		validate_input(10, 2)
	end
end

