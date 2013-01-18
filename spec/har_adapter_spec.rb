require 'spec_helper'
require "rereplay/har_adapter"

describe ReReplay, "Using a HAR file for input" do

  it "should support using a HAR file for input" do
    mock_adapter = mock(ReReplay::HARAdapter)
    ReReplay::HARAdapter.stub(:new).and_return(mock_adapter)
    mock_adapter.should_receive(:get_data)

    ReReplay::Runner.new(mock_adapter)
  end

  it "should generate correct input from an HAR file" do
    har_adapter = ReReplay::HARAdapter.new("data/example.har.json")

    data = har_adapter.get_data
    data.should == [[0.0, 'GET', 'http://www.htmlcodetutorial.com/forms/_FORM_METHOD.html'],
                    [10.0257265, 'GET', 'http://www.htmlcodetutorial.com/forms/_FORM_METHOD_POST.html'],
                    [20.8214339, 'POST', 'http://www.htmlcodetutorial.com/cgi-bin/mycgi.pl',
                     {"realname"=>"George the Wonder Boy",
                      "email"=>"george@whatever.idocs.com",
                      "nosmoke"=>"on",
                      "shakespeare"=>"on",
                      "washesdaily"=>"on",
                      "brooklyn"=>"on",
                      "dogs"=>"on",
                      "cats"=>"on",
                      "iguanas"=>"on",
                      "myself"=> "I was born in the house my father built.  I was raised on a farm with 13,000 acres of oats, and now I \r\nhate oatmeal. Much prefer the crackly taste of wheat.  I'm looking for a wife who loves to cook wheat, particularly fresh raw wheat stalks.\r\n"}
    ]]
  end

end