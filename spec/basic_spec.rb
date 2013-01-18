require 'spec_helper'

describe ReReplay, "basic functions" do
	it "should process input from array" do
		urls = ["google", "microsoft", "amazon"].map {|u| "http://#{u}.com/"}
		
		urls.each {|url| stub_request(:get, url)}
		
		interval = 0.0
		input = urls.map {|i| [interval += 0.1, :get, i]}
		
		r = ReReplay::Runner.new(input)
		lambda { r.run }.should take_between(0.seconds).and(1.second)
		
		urls.each {|url| WebMock.should have_requested(:get, url)}
	end
	
	it "should process input from string" do
		input = <<EOF
		0.1, get, http://www.google.com/
		0.6, get, http://www.amazon.com/
    0.8, post, http://www.google.com, nil, {'fake' => 'data'}
EOF
		
		stub_request(:get, "http://www.google.com/")
		stub_request(:get, "http://www.amazon.com/")
		stub_request(:post, "http://www.google.com/")

		r = ReReplay::Runner.new(input)
		lambda { r.run }.should take_between(0.seconds).and(1.second)
		
		WebMock.should have_requested(:get, "http://www.google.com/")
		WebMock.should have_requested(:get, "http://www.amazon.com/")
    WebMock.should have_requested(:post, "http://www.google.com/")
	end

  it "should make post requests" do
    input = [[0.0, :post, "http://www.htmlcodetutorial.com/cgi-bin/mycgi.pl", nil, {'fake' => 'data'}]]

    stub_request(:post, "http://www.htmlcodetutorial.com/cgi-bin/mycgi.pl")

    r = ReReplay::Runner.new(input)
    r.run

    WebMock.should have_requested(:post, "http://www.htmlcodetutorial.com/cgi-bin/mycgi.pl")
  end

	it "should throw exception on empty input" do
		r = ReReplay::Runner.new
		lambda { r.run }.should raise_error(ArgumentError, /input was empty/)
	end
end
