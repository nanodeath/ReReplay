Dir[File.join(File.dirname(__FILE__), "monitors/*.rb")].each do |monitor|
	require monitor
end
