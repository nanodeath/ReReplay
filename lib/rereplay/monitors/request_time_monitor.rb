# Simple request monitor that tracks how long requests take
module ReReplay
	class RequestTimeMonitor
		attr_reader :results
		def initialize
			@results = []
		end
	
		def finish(request)
			@results[request.index] = [request.url, request.finish - request.actual_start, request.scheduled_start, request.actual_start]
		end
	end
end
