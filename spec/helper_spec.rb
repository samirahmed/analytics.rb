$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'analytics'

module Helpers
    
  GA_REQUIRED = [:tid, :an, :t, :v, :cid]

  # Converts a query string "x=1&y=4&z=3" to {:x => 1, :y => 4, :z => 3}
  def get_query_params response
    response.should_not be_nil
    response.uri.should_not be_nil
    response.uri.query.should_not be_nil
    pairs =  response.uri.query.split('&').map do |kv| 
      k,v = kv.split('=')
      [ k.to_sym , URI.unescape(v)]
    end
    Hash[pairs]
  end

  def non_required_params(params)
    params.keys - GA_REQUIRED
  end

  def validate_required_params (params, hit_type)
    GA_REQUIRED.each{|k| k.should_not be_nil }
    params[:tid].should eql Analytics.tracking_id
    params[:an].should eql Analytics.app_name
    params[:v].should eql Analytics.protocol_version
    params[:cid].should eql Analytics.client_id
    params[:t].should eql hit_type
  end

end

RSpec.configure do |c|
  c.include Helpers
end
