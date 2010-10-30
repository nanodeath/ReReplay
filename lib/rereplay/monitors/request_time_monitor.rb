# Simple request monitor that tracks how long requests take
module ReReplay
	class RequestTimeMonitor
		attr_reader :results
		def initialize
			@results = []
		end
	
		def finish(request)
			@results[request.index] = {:url => request.url, :duration => request.finish - request.actual_start, :scheduled_start => request.scheduled_start, :actual_start => request.actual_start}
		end
	end
end
