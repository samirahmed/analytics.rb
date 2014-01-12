require_relative 'helper_spec'

describe Analytics do
 
  before :each do
    Analytics.configure "UA-XYZABCZA-1", "appname"
  end
  
  it 'should be able to log an exception with no arguments' do
     [Analytics.exception, Analytics.exception!].each do |thread|
       
       thread.should be_a_kind_of Thread
       thread.join

       params = get_query_params thread[:response]

       [:exd, :exf].each{|k| params[k].should be_nil}
       validate_required_params params, 'exception'
       non_required_params(params).should be_empty
     end
  end

  it 'should be able to log an excpetion with arguments' do
      
     thread = Analytics.exception description: "error description", fatal?: true
     thread.should be_a_kind_of Thread
     thread.join

     params = get_query_params thread[:response]
     validate_required_params params, 'exception'
     params[:exd].should eql 'error description'
     params[:exf].should eql '1'

  end

end
