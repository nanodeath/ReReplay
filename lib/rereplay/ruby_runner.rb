require 'ostruct'
require 'thread'
require 'net/http'
require 'uri'
require 'monitor'

module ReReplay
	class TestDurationExceeded < StandardError; end
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
		
		def prepare
			p = profile
		
			max_time = @input.max {|a, b| a[0] <=> b[0]}[0]
			
			loop_count = 1
			if(p[:when_input_consumed] == :loop)
				if(max_time < p[:run_for])
					loop_count = (p[:run_for].to_f / max_time).ceil
				end
			end
			if(loop_count > 1)
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
		end
	
		def run
			validate_input
			p = profile
			done_count = 0
			# request monitors with a start method
			request_monitors_start = request_monitors.select {|mon| mon.respond_to? :start}
			# request monitors with a finish method
			request_monitors_finish = request_monitors.select {|mon| mon.respond_to? :finish}
			tg = ThreadGroup.new
			q = Queue.new
			q.extend MonitorMixin
			waiters_cond = q.new_cond
			
			prepare
			start_time = nil
			index = 0
			requests_to_make = @input.map do |r| 
				a = r.dup
				a[4] = index
				index += 1
				a
			end
			thread_count = 20
			done = 0
			total_requests = @input.length
			max_delay = 0
			parent_thread = Thread.current
			Thread.abort_on_exception = true
			ready_for_processing = false
			gatekeeper = Thread.new do
				q.synchronize do
					waiters_cond.wait_until { ready_for_processing }
				end
				until requests_to_make.empty?
					task = requests_to_make.shift
					since_start = Time.new - start_time
					time_until_next_task = task[0] - since_start
				
					if(time_until_next_task > 0)
						sleep time_until_next_task
					end
					
					q << task
				end
			end
			
			thread_count.times do
				t = Thread.new do
					while true
						task = q.pop
						now = Time.new
						since_start = now - start_time
						delay = since_start - task[0]
						if(delay > max_delay) then max_delay = delay; end
						url = URI.parse(task[2])
						req = Net::HTTP::Get.new(url.path)
						headers = task[3]
						request = OpenStruct.new(:url => task[2], :scheduled_start => task[0], :index => task[4], :http_method => task[1], :headers => headers)
						if headers && headers.any?
							headers.each_pair do |header, value|
								req[header] = value
							end
						end
						# this connection can actually take ~300ms...is there a better way?
						Net::HTTP.start(url.host, url.port) do |http|
							http.read_timeout = p[:timeout]
							status = nil
							begin
								#request.actual_start = Time.now - start_time
								request.actual_start = now - start_time
								resp = http.request(req)
								request_monitors_start.each {|mon| mon.start(request)}
							rescue Timeout::Error
								status = :timeout
							end
							if status.nil?
								status = resp.code
							end
							time_finished = Time.now - start_time
							request.finish = time_finished
							request.status = status
							begin
								request_monitors_finish.each {|mon|	mon.finish(request)}
							rescue => e
								parent_thread.raise e
							end
							q.synchronize do
								done += 1
								waiters_cond.broadcast
							end
						end
					end
				end
				tg.add t
			end
			test_duration_exceeded = false
			q.synchronize do
				ready_for_processing = true
				start_time = Time.now
				waiters_cond.broadcast
			end
			timeout_thread = Thread.new do
				sleep_duration = start_time + p[:run_for] - Time.now
				sleep sleep_duration
				q.synchronize do
					test_duration_exceeded = true
					waiters_cond.broadcast
				end
			end
			periodic_monitor_threads = []
			periodic_monitors.each do |mon|
				interval = mon.respond_to?(:interval) ? mon.interval : 5
				periodic_monitor_threads << Thread.new do
					i = 0
					while true
						mon.tick(Time.now - start_time)
						i += 1
						time_to_next = start_time + (interval * i) - Time.now
						sleep time_to_next if time_to_next > 0
					end
				end
			end
			q.synchronize do
				waiters_cond.wait_while {	done < total_requests && !test_duration_exceeded }
			end
		ensure
			gatekeeper.kill if gatekeeper
			tg.list.each {|t| t.kill} if tg
			periodic_monitor_threads.each {|t| t.kill} if periodic_monitor_threads
		end

		def profile=(new_profile)
			@profile = {
				:run_for => 5,
				:when_input_consumed => :stop,
				:timeout => 1,
				:rampup => [1.0, 1.0],
				:rampup_method => :linear
			}
			if(new_profile.is_a? Hash)
				@profile.merge!(new_profile)
			end
		end
		def profile
			if(@profile.nil?)
				self.profile = {}
			end
			@profile
		end
	end
end
