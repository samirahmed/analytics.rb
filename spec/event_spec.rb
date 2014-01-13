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
    validate_required_params params, 'event'
    [:ec, :ea, :ev, :el].each{|k| params[k].should be_nil}
  end

  it 'should be able to accept optional parameters' do
    thread = Analytics.event category: "AppStart", action: "fork", value: 1, label: "label"
    thread.should be_a_kind_of Thread
    thread.join

    params = get_query_params thread[:response]
    validate_required_params params, 'event'
    [:ec, :ea, :ev, :el].each{|k| params.should_not be_nil}
  end

  it 'should ignore unknown parameters' do
    thread = Analytics.event category: "AppStart", badparam: 124
    thread.should be_a_kind_of Thread
    thread.join

    params = get_query_params thread[:response]
    validate_required_params params, 'event'
    non_required_params(params).should eql [:ec]
  end

  it 'should not allow invalid category, action or label values' do
    Analytics.raising = true
    
    expect{ Analytics.event! category: "A"*151 }.to raise_error(Analytics::AnalyticsError)
    Analytics.event(category: "A"*151).should be_nil

    expect{ Analytics.event! action: "A"*501 }.to raise_error(Analytics::AnalyticsError)
    Analytics.event(action: "A"*501).should be_nil

    expect{ Analytics.event! label: "A"*501 }.to raise_error(Analytics::AnalyticsError)
    Analytics.event(label: "A"*5010).should be_nil
  end
end
