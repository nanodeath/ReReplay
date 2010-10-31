require 'rubygems'
#$: << "../rereplay/lib"
require 'bundler/setup'
require 'rereplay'
require 'sinatra'
require "rereplay/monitors"
require "sequel"

cxn_string = "sqlite::memory:"
begin
	require 'sqlite3'
rescue LoadError
	require 'jdbc/sqlite3'
	cxn_string = "jdbc:" + cxn_string
end

def migrate(database)
	database.create_table :requests do
		Fixnum :id
		String :url
		String :start_time
		String :stop_time
		Float :delay
		
		index :id, :unique => true
	end
end

input = []
input << [0, :get, "http://www.target.com/"]
input << [0.3, :get, "http://www.target.com/Mens/b/ref=nav_t_spc_2_0?ie=UTF8&node=1041828"]
input << [0.8, :get, "http://www.target.com/Baby/b/ref=nav_t_spc_3_0?ie=UTF8&node=1038590"]
input << [1.0, :get, "http://www.target.com/Kids/b/ref=nav_t_spc_4_0?ie=UTF8&node=1041972"]
input << [1.4, :get, "http://www.target.com/Shoes/b/ref=nav_t_spc_5_0?ie=UTF8&node=1239516011"]
input << [1.9, :get, "http://www.target.com/Beauty/b/ref=nav_t_spc_6_0?ie=UTF8&node=1042004"]
input << [2.6, :get, "http://www.target.com/Home/b/ref=nav_t_spc_7_0?ie=UTF8&node=3151061"]
input << [2.7, :get, "http://www.target.com/Kitchen-Dining/b/ref=nav_t_spc_8_0?ie=UTF8&node=1038578"]
input << [2.75, :get, "http://www.target.com/Furniture/b/ref=nav_t_spc_9_0?ie=UTF8&node=1038614"]
input << [2.758, :get, "http://www.target.com/Toys/b/ref=nav_t_spc_10_0?ie=UTF8&node=1038620"]
input << [2.76, :get, "http://www.target.com/Electronics/b/ref=nav_t_spc_11_0?ie=UTF8&node=1038598"]

class RealtimeMonitor
	def initialize(db)
		@db = db
	end
	def start(request)
		@db.run("replace into requests(id, url, start_time, delay) values('%s', '%s', '%s', '%s')" % [request.index, request.url, request.scheduled_start, request.actual_start - request.scheduled_start])
	end
	def finish(request)
		@db.run("replace into requests(id, url, start_time, stop_time, delay) values('%s', '%s', '%s', '%s', '%s')" % [request.index, request.url, request.scheduled_start, request.finish, request.actual_start - request.scheduled_start])	
	end
end

# track whether we're done processing or not
done = nil

get "/" do
  erb :index
end

# main database reference
db = nil

post "/run" do
	done = :not
	db = Sequel.connect(cxn_string)
	migrate(db)
	mon = RealtimeMonitor.new(db)
	
	r = ReReplay::Runner.new(input)
	r.request_monitors << mon
	
	Thread.new { r.run ; done = :almost }
	erb :index
end

get "/results" do
	if done != :done
		# this is to ensure we get one final execution
		if done == :almost
			done = :done
		end
		@results = db[:requests].order_by(:id).all unless db.nil?
		erb :results
	else
		"0"
	end
end
