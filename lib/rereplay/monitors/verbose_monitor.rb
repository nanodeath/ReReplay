# Prints out start and stop times of requests
class VerboseMonitor
	def start(request)
		puts "started request #{request.index}:(#{request.url}) at #{request.actual_start}"
	end
	
	def finish(request)
		puts " - finished request #{request.index}, status #{request.status}"
	end
end

