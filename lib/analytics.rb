module Analytics
  
  class << self
    attr_accessor :debug_mode, :raising?
    
    @@raising = false
    @@debug_mode = false
  end

  def debug( msg )
    (print "[#{_class}]=> #{msg}") if Analytics.debug_mode
  end

  def event( category, action, opts = {})
    execute 
  end

  def exception( desc , fatal = false, opts = {})
    
  end

  private 

  ENDPOINT = "http://www.google-analytics.com/collect"

  GLOBAL_OPT = {
    session => {key:sc, nominal:["start", "end"]},
    anonymize_ip => {key:aip, value:"1"},
    app_name => {key:a, byte:100},
    app_version => {key:av, byte:100},
    non_interaction => {key:ni, value:"1"},
    client_id => {key:cid, required:true},
    tracking_id => {key:tid, required:true},
    protocol_version => {key:v, required:true},
  }

  EXCEPTION_OPT = {
    exception => {key:exd, byte:150, required:true},
    fatal => {key:exf, value:"1"},
    hit_type => {key:t, value:"exception"}
  }

  EVENT_OPT = {
    hit_type => {key:t, value:"event"},
    label => {key:ev, nil, byte:500},
    action => {key:ea,, byte:500, required:true},
    category => {key:ec, byte:150, required:true},
    value => {key:ev}
  }

  def extract( opt, value)
    
    return {} if opt.nil? || opt[:key].nil?

    # Get the option key
    _key = opt[:key]

    # Get option default value, or user specified value
    _value = opt[:value] || value
    
    # Ensure non null on optional values
    if _value.nil? && opt[:required]
      raise "No Value Provided for Required Parameter #{url_key}" if Analytics.raising?
    end

    # Ensure the byte limit is not exceed
    if opt[:byte] && _value.bytesize < opt[:byte]
      raise "#{_value} is larger than #{opt[:byte]} bytes" if Analytics.raising?
    end

    # Ensure the value is one of the accepted values
    if opt[:nominal] && !opt[:nominal].include?(_value)
      raise "#{_nominal}"
    end

    return {url_key => url_value}
  end
  
  def transform(original, options)
    original.inject({}) do |result, (key,value)|
      result.merge(extract options[key] , value )
    end
  end
 
  def execute(opts)
    
    params = transform(opts, GLOBAL_OPT)

    case opts[:hit_type]
      when "event"
        params.merge transform(opts, EVENT_OPT)
      when "exception"
        params.merge transform(opts, EXCEPTION_OPT)
    end
    
    thread do
      
      _uri = URI(ENDPOINT)
      _http = Net::HTTP.new(_uri.host, _uri.port)
      
      _uri.query = URI.encode_www_form( params )
      _req = Net::HTTP::Get.new(uri.request_uri)

      # todo add headers here ...
      
      _resp = _http.request(_req)

      debug(_resp.code)
      _resp.each{|name, value| debug("#{name}:#{value}")}
    end

  end

  #GA_OPTS = {
    #v => 1,            # *Protocol version 
    #tid => nil,        # *Tracking ID
    #cid => nil,        # *Client ID
    #t => nil,          # *Hit Type, default is Event
    #ni => nil,         # 1 if non-interaction hit
    #ec => nil,         # Event Category
    #ea => nil,         # Event Action
    #el => nil,         # Event String Label
    #ev => nil,         # Numeric Event Value
    #exd => nil,        # Exception description
    #exf => nil,        # Exception is fatal?
    #an => nil,         # Application Name
    #av => nil,         # Application Version
    #aip => nil,        # 1 or 0, Anonymize IP address of sender
    #qt => nil,         # Queue Time delay between hit and actual report
    #sc => "end",       # Session Control ('start' or 'end')
    #z => nil           # Cache Buster
  #}
end
