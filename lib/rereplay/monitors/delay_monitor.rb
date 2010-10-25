# Simple request monitor that tracks the delays of requests
class DelayMonitor
	attr_reader :results
	def initialize
		@results = []
	end
	
	def start(request)
		@results[request.index] = [request.url, request.actual_start - request.scheduled_start]
	end
end

