module Analytics
  class Measure
    require  'net/http'
    require  'socket'
    require  'uri'

    attr_accessor :debug_mode, :raise_errors, :app_name, :app_version, :client_id, :tracking_id, :protocol_version, :anonymize_ip

    def initialize(tid, opts = {})
     
      # set tracking id, ensure is not nil
      @tracking_id = tid
      return nil if tid.nil? && (tid =~ /UA-[\w]{4}-\w/)

      # by default ignore errors
      @ignore_errors = false
      
      # set debug mode to be true
      @debug = false

      # Generate a random client Id
      @client_id = Random.new(Socket.gethostname.to_i).rand(2**31..2**32).to_s
     
      # Get the remainder of values
      opts.each do |key,value|
        return unless self.respond_to?(key.to_s+"=")
        self.send(key.to_s+"=",value)
      end
    end

    def debug_print( msg )
      (print "[#{_class}]=> #{msg}") if @debug_mode
    end

    [:event, :exception].each do |method|
      define_method(method) do |args|
        begin
          self.class.send("#{method}!".to_sym, *args)
        rescue
          nil
        end
      end
    end

    def event!( category, action, opts = {})
      execute opts.merge({ 
        category:category, 
        action:action,
        hit_type:"event"
      })
    end

    def exception!( desc , fatal = false, opts = {})
     execute opts.merge({
      description:description,
      fatal?:fatal,
      hit_type:"event"
     })
    end
    
    # private
    
    def globals
      Hash[instance_variables.map{ |name| [name[1..-1].to_sym, instance_variable_get(name)]}]
    end

    ENDPOINT = "http://www.google-analytics.com/collect"

    GLOBAL_OPT = {
      :session => {key:"sc", nominal:["start", "end"]},
      :anonymize_ip => {key:"aip", value:"1"},
      :app_name => {key:"a", byte:100},
      :app_version => {key:"av", byte:100},
      :non_interaction => {key:"ni", value:"1"},
      :client_id => {key:"cid", required:true},
      :tracking_id => {key:"tid", required:true},
      :protocol_version => {key:"v", required:true},
    }

    EXCEPTION_OPT = {
      :exception => {key:"exd", byte:150, required:true},
      :fatal? => {key:"exf", value:"1"},
      :hit_type => {key:"t", value:"exception"}
    }

    EVENT_OPT = {
      :hit_type => {key:"t", value:"event"},
      :label => {key:"ev",  byte:500},
      :action => {key:"ea", byte:500, required:true},
      :category => {key:"ec", byte:150, required:true},
      :value => {key:"ev"}
    }

    def extract( opt, value)
      
      return {} if opt.nil? || opt[:key].nil?

      # Get the option key
      _key = opt[:key]

      # Get option default value, or user specified value
      _value = opt[:value] || value
      
      # Ensure non null on optional values
      if _value.nil? && opt[:required]
        raise "No Value Provided for Required Parameter #{_key}" unless @ignore_errors
      end

      # Ensure the byte limit is not exceed
      if opt[:byte] && _value.bytesize > opt[:byte]
        raise "#{_value} is larger than #{opt[:byte]} bytes" unless @ignore_errors
      end

      # Ensure the value is one of the accepted values
      if opt[:nominal] && !opt[:nominal].include?(_value) 
        raise "#{_nominal}" unless ignore?
      end

      return {_key => _value}
    end
    
    def transform(original, options)
      original.inject({}) do |result, (key,value)|
        result.merge(extract options[key] , value )
      end
    end
   
    def execute(opts)
      
      params = globals
      params.merge opts
      params = transform( params, GLOBAL_OPT )

      case opts[:hit_type]
        when "event"
          params.merge transform(opts, EVENT_OPT)
        when "exception"
          params.merge transform(opts, EXCEPTION_OPT)
      end
      
      thread do
        
        _uri = URI(Analytics)
        _http = Net::HTTP.new(_uri.host, _uri.port)
        
        _uri.query = URI.encode_www_form( params )
        _req = Net::HTTP::Get.new(uri.request_uri)

        # todo add headers here ...
        
        _resp = _http.request(_req)

        debug_print _resp.code
        _resp.each{ |name, value| debug_print "#{name}:#{value}" }
      end

      true

    end
  end
end

