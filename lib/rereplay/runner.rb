module ReReplay
	class Runner
		attr_accessor :periodic_monitors
		attr_accessor :request_monitors

		def initialize(input=nil)
			if(!input.nil?)
				self.input = input
			end
			@periodic_monitors = []
			@request_monitors = []
		end

		def input=(input)
			if(input.is_a? Array)
				@input = input
			elsif(input.respond_to? :readlines)
				@input = input.readlines
			elsif(input.respond_to? :split)
				@input = input.split("\n").map do |i| 
					i = i.strip.split(",").map {|j| j.strip}
					i[0] = i[0].to_f
					i[1] = i[1].to_sym
					i
				end
			else
				raise "Invalid input, expected Array, #readlines, or #split"
			end
		end
	
		def validate_input
			if(@input.nil? || @input.empty?)
				raise ArgumentError, "Nothing to process (input was empty)"
			end
			valid_methods = [:get, :head]
			@input.each_with_index do |a, i|
				if(!a[0].is_a? Numeric)
					raise ArgumentError, "Expected element at index 0 of input #{i+1} to be Numeric; was #{a[0]}"
				end
				if(!a[1].is_a?(Symbol) || !valid_methods.include?(a[1]))
					raise ArgumentError, "Expected element at index 1 of input #{i+1} to be a symbol in #{valid_methods.inspect}; was #{a[1].inspect}"
				end
				if(!a[2].is_a? String)
					raise ArgumentError, "Expected element at index 2 of input #{i+1} to be a String; was #{a[2]}"
				end
				if(!a[3].nil? && !a[3].is_a?(Hash))
					raise ArgumentError, "Expected element at index 3 of input #{i+1} to be nil or a Hash; was #{a[3]}"
				end
				# TODO post data
			end
		end
	
		def run
			validate_input
			p = profile
			done_count = 0
			# request monitors with a start method
			request_monitors_start = request_monitors.select {|mon| mon.respond_to? :start}
			# request monitors with a finish method
			request_monitors_finish = request_monitors.select {|mon| mon.respond_to? :finish}
			EM::run do
				EM.set_quantum(p[:timer_granularity])
				start = Time.now
				setup_time = p[:time_for_setup]
				actual_start = start + setup_time
			
				loop_count = 1
			
				max_time = @input.max {|a,b| a[0] <=> b[0]}[0]
				#avg_time = @input.inject(0){|memo, i| i[0] + memo}.to_f / @input.length
				if(p[:when_input_consumed] == :loop)
					if(max_time < p[:run_for])
						loop_count = (p[:run_for].to_f / max_time).ceil
					end
				end
			
				if(loop_count > 1)
					# If we need to have multiple iterations of the data,
					# we pad that on here
					new_inputs = []
					2.upto(loop_count) do |loop|
						new_input = @input.map do |i|
							new_i = i.dup
							new_i[0] += max_time * (loop - 1)
							new_i
						end
						new_inputs << new_input
					end
					new_inputs.each {|input| @input += input}
				end
				real_max_time = [max_time * loop_count, p[:run_for]].min
				if(p[:rampup][0] != p[:rampup][1] || p[:rampup][0] != 1.0)
					case p[:rampup_method]
					when :linear
						sr = 1.0 / p[:rampup][0]
						fr = 1.0 / p[:rampup][1]
						prev_time = 0
						new_prev_time = 0
						@input.map! do |a|
							time = a[0].to_f
							percent = time / real_max_time
							fraction = sr + (fr - sr)*(time / real_max_time)
							tmp = a[0]
							a[0] = (time - prev_time)*fraction + new_prev_time
							prev_time = tmp
							new_prev_time = a[0]
							a
						end
					end
				end
				total_urls = @input.length
				
				requests = []
				# pregenerate requests
				@input.each do |a|
					requests << EventMachine::HttpRequest.new(a[2])
				end

				@input.each_with_index do |a, i|
					scheduled_start = a[0]
					request = OpenStruct.new(:url => a[2], :scheduled_start => scheduled_start, :index => i, :http_method => a[1])
					delay = actual_start + scheduled_start
					if(delay < Time.now)
						raise "Not enough time allotted for setup!  Try increasing time_for_setup in your profile."
					end
					delay -= Time.now
					EM::add_timer(delay) do
						EM.defer do
							begin
								request.actual_start = Time.now - actual_start
								http = requests[i].send(request.http_method, :timeout => p[:timeout])
								request_monitors_start.each {|mon| mon.start(request)}
							rescue => e
								EM.next_tick do
									raise e
								end
							end
							callback = lambda {
								time_finished = Time.now - actual_start
								request.finish = time_finished
								request.status = http.response_header.status
								if(request.status == 0)
									request.status = :timeout
								end
								begin
									request_monitors_finish.each {|mon|	mon.finish(request)}
								rescue => e
									EM.next_tick do
										raise e
									end
								end
								done_count += 1
								if(done_count == total_urls && p[:when_input_consumed] == :stop)
									EM.stop
								end
							}
							http.errback { callback.call }
							http.callback { callback.call }
						end
					end
				end
				periodic_monitors.each do |mon|
					interval = mon.respond_to?(:interval) ? mon.interval : 5
					EM::add_timer(actual_start - Time.now - interval) do
						EM::add_periodic_timer(interval) do
							mon.tick(Time.now - actual_start)
						end
					end
				end
				run_for = actual_start + p[:run_for] - Time.now
				EM::add_timer(run_for) do
					#puts "run_for hit (#{run_for})"
					EM.stop
				end
			end
		end

		def profile=(new_profile)
			@profile = {
				:time_for_setup => 1,
				:timer_granularity => 50,
				:run_for => 5,
				:when_input_consumed => :stop,
				:timeout => 1,
				:rampup => [1.0, 1.0],
				:rampup_method => :linear
			}
			if(new_profile.is_a? Hash)
				@profile.merge!(new_profile)
			end
			# TODO validate profile
		end
		def profile
			if(@profile.nil?)
				self.profile = {}
			end
			@profile
		end
	end
end
