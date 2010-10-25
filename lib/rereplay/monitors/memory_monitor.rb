# Simple periodic monitor that tracks ongoing memory usage
class MemoryMonitor
	attr_reader :results
	attr_accessor :interval
	
	def initialize
		@results = []
	end
	def tick(time)
		# http://laurelfan.com/2008/1/15/ruby-memory-usage
		memory_usage = `ps -o rss= -p #{Process.pid}`.to_i
		@results << [time, memory_usage]
	end
end
