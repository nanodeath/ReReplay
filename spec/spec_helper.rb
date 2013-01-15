require "rubygems"
require "bundler"
Bundler.setup(:default, :test)

require "rereplay"
require "rereplay/monitors/memory_monitor"
require "rereplay/monitors/request_time_monitor"
require "rereplay/monitors/delay_monitor"
require "rereplay/monitors/verbose_monitor"
require "rereplay/monitors/timeout_failer"

require "rspec"
require "webmock/rspec"
require 'active_support/time'
require 'spec_custom_matchers'

require "rereplay/har_adapter"

RSpec.configure do |config|
	config.include WebMock::API
	config.include CustomMatchers
end

def generate_input(length, opts={})
	interval = opts[:start] || 0.0
	interval_increment = opts[:interval] || 0.1
	urls = ["google", "microsoft", "amazon", "mint", "yahoo", "windowshop", "xbox", "samsung", "qwest", "comcast"][0...length].map {|u| "http://#{u}.com/"}
	if(opts[:timeout])
		urls.each {|url| stub_request(:get, url).to_timeout}
	else
		urls.each {|url| stub_request(:get, url)}
	end
	if(opts[:start_at_0])
		interval -= interval_increment
	end
	input = urls.map {|i| [interval += interval_increment, :get, i]}
	input
end

def validate_input(length, count=1)
	urls = ["google", "microsoft", "amazon"][0...length].map {|u| "http://#{u}.com/"}
	urls.each {|u| WebMock.should have_requested(:get, u).times(count)}
end

def capture_stdout
	s = StringIO.new
	$stdout = s
	yield
	s.string
ensure
	$stdout = STDOUT
end
