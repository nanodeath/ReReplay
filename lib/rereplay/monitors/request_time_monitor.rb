# Simple request monitor that tracks how long requests take
class RequestTimeMonitor
	attr_reader :results
	def initialize
		@results = []
	end
	
	def finish(request)
		@results[request.index] = [request.url, request.finish - request.actual_start, request.scheduled_start]
	end
end
