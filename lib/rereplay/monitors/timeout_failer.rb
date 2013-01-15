module ReReplay
	class TimeoutFailer
		class Timeout < StandardError; end
		def initialize(max_timeouts=1)
			@max_timeouts = max_timeouts
			@timeouts = 0
		end

		def finish(request, response=nil)
			if(request.status == :timeout)
				@timeouts += 1
			end
			if(@timeouts >= @max_timeouts)
				raise Timeout, "TimeoutFailer triggered because timeout limit #{@max_timeouts} was reached"
			end
		end
	end
end
