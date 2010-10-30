require 'spec_helper'

describe ReReplay, "basic functions" do
	it "should process input from array" do
		urls = ["google", "microsoft", "amazon"].map {|u| "http://#{u}.com/"}
		
		urls.each {|url| stub_request(:get, url)}
		
		interval = 0.0
		input = urls.map {|i| [interval += 0.1, :get, i]}
		
		r = ReReplay::Runner.new(input)
		lambda { r.run }.should take_between(1.second).and(2.seconds)
		
		urls.each {|url| WebMock.should have_requested(:get, url)}
	end
	
	it "should process input from string" do
		input = <<EOF
		0.1, get, http://www.google.com/
		0.6, get, http://www.amazon.com/
EOF
		
		stub_request(:get, "http://www.google.com/")
		stub_request(:get, "http://www.amazon.com/")
		
		r = ReReplay::Runner.new(input)
		lambda { r.run }.should take_between(1.second).and(2.seconds)
		
		WebMock.should have_requested(:get, "http://www.google.com/")
		WebMock.should have_requested(:get, "http://www.amazon.com/")
	end
	
	it "should throw exception on empty input" do
		r = ReReplay::Runner.new
		lambda { r.run }.should raise_error(ArgumentError, /input was empty/)
	end
end
