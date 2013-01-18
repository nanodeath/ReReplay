# encoding: utf-8

require 'time'
require 'json'
require 'cgi'

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
      @entries = parse contents
      @entries.sort! {|entry1,entry2| Time.parse(entry1[:request_time]) <=> Time.parse(entry2[:request_time])}

      to_data
    end

    def to_data
      t0 = nil
      @entries.map do |entry|
        request_time = entry[:request_time]
        t0 ||= Time.parse(request_time)
        offset = Time.parse(request_time) - t0
        input = [offset, entry[:method], entry[:url]]
        input.push(entry[:post_params]) if entry[:post_params]
        input
      end
    end

    def add_offsets
      t0 ||= Time.parse(startedDateTime)
      offset = Time.parse(startedDateTime) - t0
    end

    def extract_post_params(post_params)
      post_params.inject({}) do|acc, params_hash|
        acc.update(params_hash['name'] => params_hash['value'])
      end
    end

    def parse(contents)
      contents['log']['entries'].map do|entry|
        request = entry['request']
        url = request['url']
        method = request['method']
        request_time = entry['startedDateTime']
        entry = {:request_time => request_time, :method => method, :url => url}
        if method == 'POST'
          if request['postData']['mimeType'] == 'application/x-www-form-urlencoded'
            entry[:post_params] = extract_post_params(request['postData']['params'])
          else
            #TODO: Add support for other mime types (eg. multi-part forms, etc.)
          end
        end
        entry
      end
    end

  end
end
