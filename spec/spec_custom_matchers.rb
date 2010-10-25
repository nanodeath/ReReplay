# Custom matchers
module CustomMatchers
	class TimeTaken
		def initialize(lower_seconds, upper_seconds=nil)
			@lower_seconds = lower_seconds
			@upper_seconds = upper_seconds
		end
	
		def matches?(given_proc)
			range = @lower_seconds..@upper_seconds
			start = Time.now
			given_proc.call
			fin = Time.now
			@diff = fin - start
			range.include?(@diff)
		end

		def and(upper_seconds)
			@upper_seconds = upper_seconds
			self
		end
	
		def failure_message_for_should
			"expected block to take between #{@lower_seconds} and #{@upper_seconds} seconds, but took #{@diff} seconds"
		end
	
		def failure_message_for_should_not
			"expected block not to take between #{@lower_seconds} and #{@upper_seconds} seconds, but took #{@diff} seconds"
		end	
	end

	def take_between(lower_seconds, upper_seconds=nil)
		TimeTaken.new(lower_seconds, upper_seconds)
	end
end
