require_relative 'helper_spec'

describe Analytics do
  
  before :each do
    Analytics.configure "UA-XYZABCZA-1", "AnalyticsTest"
  end

  it 'should be able to log events with just a category and action' do
     result = Analytics.event! "Category", "Action"
     result.is_a?(Thread).should be_true
  end

  it 'should be able to accept optional parameters' do
     result = Analytics.event! "Category", "Action", :label => "myLabel", :value => 1
     result.is_a?(Thread).should be_true
  end

  it 'should ignore unknown parameters' do
     result = Analytics.event! "Category", "Action", :mySpecialVar => "myspecialvar"
     result.is_a?(Thread).should be_true
  end
end
