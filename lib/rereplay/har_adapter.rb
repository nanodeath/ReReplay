# encoding: utf-8

require 'time'
require 'json'

module ReReplay
  class HARAdapter
    def initialize(path)
      @path = path
    end

    def clean_contents!(contents)
      contents.gsub!(/\A\xEF\xBB\xBF/, '')
      contents.force_encoding 'UTF-8'
    end

    def get_data
      f = File.open(@path)
      contents = f.read
      clean_contents!(contents)

      contents = JSON.parse(contents)
      parse contents
      @entries.sort! {|entry1,entry2| Time.parse(entry1[:request_time]) <=> Time.parse(entry2[:request_time])}

      to_data
    end

    def to_data
      data = []
      t0 = nil

      @entries.each do |entry|
        request_time = entry[:request_time]
        t0 ||= Time.parse(request_time)
        offset = Time.parse(request_time) - t0
        data.push([offset, entry[:method], entry[:url]])
      end
      data
    end

    def add_offsets
      t0 ||= Time.parse(startedDateTime)
      offset = Time.parse(startedDateTime) - t0
    end

    def parse(contents)
      @entries = []
      contents['log']['entries'].each do|entry|
        request = entry['request']
        url = request['url']
        method = request['method']
        request_time = entry['startedDateTime']

        @entries.push({:request_time => request_time, :method => method, :url => url})
      end
    end

  end
end
