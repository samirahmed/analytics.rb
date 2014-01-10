require_relative 'helper_spec'

describe Analytics do
 
  before :each do
    Analytics.configure "UA-XYZABCZA-1", "appname"
  end

  it 'should be able to log an event with no arguments' do
     thread = Analytics.event!
     thread.should be_a_kind_of Thread
     thread.join

     params = get_query_params thread[:response]
     [:ec, :ea, :ev, :el].each{|k| params[k].should be_nil}
     params[:t].should eql 'event'
     params[:tid].should eql Analytics.tracking_id
  end

  it 'should be able to accept optional parameters' do
     thread = Analytics.event! category: "AppStart", action: "fork", value: 1, label: "label"
     thread.should be_a_kind_of Thread
     thread.join

     params = get_query_params thread[:response]
     params[:t].should eql 'event'
     [:ec, :ea, :ev, :el].each{|k| params.should_not be_nil}
  end

  it 'should ignore unknown parameters' do
     thread = Analytics.event! category: "AppStart", badparam: 124
     thread.should be_a_kind_of Thread
     thread.join

     expected_keys = [:tid, :cid, :v, :t, :ec, :an]
     params = get_query_params thread[:response]
     params.keys.count.should eql expected_keys.count
     (expected_keys - params.keys).should be_empty
  end
end
