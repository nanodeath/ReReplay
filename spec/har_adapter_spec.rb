require 'spec_helper'

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
                    [20.8214339, 'POST', 'http://www.htmlcodetutorial.com/cgi-bin/mycgi.pl']
    ]
  end

end