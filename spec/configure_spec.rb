
require_relative 'helper_spec'

describe Analytics do

  before :each do
    @tid = "UA-XYZXYZ1-1"
    @name = "myapp" 
  end

  it 'should be configurable with only the appname and tracking id' do
    Analytics.configure(@tid, @name)
    Analytics.tracking_id.should eql @tid
    Analytics.app_name.should eql @name
  end

  it 'should autogenerate a client id that is a valid uuid' do
    Analytics.configure(@tid, @name)
    is_uid = Analytics.client_id =~ /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
    is_uid.should be_true
  end

  it 'should default to debug false' do
    Analytics.configure(@tid, @name)
    Analytics.debug.should be_false
  end

  it 'should default to protocol version 1' do
    Analytics.configure(@tid, @name)
    Analytics.protocol_version.should eql '1'
  end

  it 'should take optional arguments' do
    Analytics.configure('UA-12312312-1', "hacks", :app_version => "0.1", :anonymize_ip => true)
    Analytics.tracking_id.should eql 'UA-12312312-1'
    Analytics.app_name.should eql 'hacks'
    Analytics.app_version.should eql '0.1'
    Analytics.anonymize_ip.should be_true
  end
  
  it 'should not complain when optional arguments are not attributes' do
    Analytics.configure('UA-12312312-1', :bad_attribute => "uhoh")
    Analytics.tracking_id.should eql 'UA-12312312-1'
  end

end
