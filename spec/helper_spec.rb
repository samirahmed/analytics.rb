$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'analytics'

module Helpers

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

end

RSpec.configure do |c|
  c.include Helpers
end
