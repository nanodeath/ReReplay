# Prints out start and stop times of requests
module ReReplay
	class VerboseMonitor
		def start(request)
			puts "started request #{request.index}:(#{request.url}) at #{request.actual_start}"
		end

    def finish(request, response=nil)
      puts " - finished request #{request.index}, status #{request.status}, #{response.body.bytesize} bytes"
    end
	end
end
