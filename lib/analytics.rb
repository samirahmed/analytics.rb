class Analytics 
   class << self
    require  'net/http'
    require  'socket'
    require  'open-uri'
    require  'securerandom'

    attr_accessor :debug, :raising,                                        # Gem Settings
                  :app_name, :client_id, :tracking_id, :protocol_version,  # G.A Required
                  :anonymize_ip, :session, :app_version                    # G.A Optional

    def configure(tid, appname,  opts = {})

      # set tracking id and appname, required!
      @tracking_id = tid
      @app_name = appname

      # by default ignore errors
      @raise = false
      
      # configure settings
      @debug = @debug

      # Generate a random client Id
      @client_id = SecureRandom.uuid()
      @protocol_version = '1'

      # Get the remainder of values
      opts.each do |key,value|
        return unless self.respond_to?(key.to_s+"=")
        self.send(key.to_s+"=",value)
      end
      
      # Return the configuration hash
      globals

    end

    [:event, :exception].each do |method|
      define_method(method) do |*args|
        begin
          self.send("#{method}!".to_sym, *args)
          puts (Time.now-start).to_f * 1000.0
        rescue Exception => e
          trace e.message
          trace e.backtrace.inspect
          nil
        end
      end
    end

    def event!( category, action, opts = {})
      puts category
      puts action
      puts opts.inspect
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
      hit_type:"exception"
     })
    end
    
    # private
    
    def globals
      Hash[instance_variables.map{ |name| [name[1..-1].to_sym, instance_variable_get(name)]}]
    end

    GLOBAL_OPT = {
      :session => {key:"sc", nominal:["start", "end"]},
      :anonymize_ip => {key:"aip", value:"1"},
      :app_name => {key:"an", byte:100, required:true},
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
     
      result = {}

      if _value.nil?
        err "nil value for required parameter #{_key}" if opt[:required]
      elsif opt[:byte] && _value.bytesize > opt[:byte]
        err "#{_value} is larger than #{opt[:byte]} bytes"
      elsif opt[:nominal] && !opt[:nominal].include?(_value) 
        err "#{_key} must equal #{opt[:nominal].inspect} - not #{_nominal}"
      elsif _value
        result = {_key => _value}
      end

      result
    end
    
    def transform(original, options)
      original.inject({}) do |result, (key,value)|
        result.merge(extract options[key] , value )
      end
    end
   
    def execute(opts)
      
      err "Invalid TrackingId" unless @tracking_id && (@tracking_id =~ /UA-\w{4,8}-\w{1,2}/)

      query = globals
      query.merge! opts
      query = transform( query, GLOBAL_OPT )

      case opts[:hit_type]
        when "event"
          query.merge! transform(opts, EVENT_OPT)
        when "exception"
          query.merge! transform(opts, EXCEPTION_OPT)
      end
      
      trace query.inspect 
      
      thread = Thread.new do
        
        _uri = URI::HTTP.build({
          :host => "www.google-analytics.com",
          :path => "/collect",
          :query => query.map{|k,v| "#{k}=#{URI.escape(v)}"}.join('&')
        })

        trace _uri.to_s 
        _resp = Net::HTTP.get_response(_uri)

        trace _resp.code
        _resp.each{ |name, value| trace "#{name}:#{value}" }
      end
      
      thread
    end

    def trace msg
      puts(msg) if @debug
    end

    def err msg 
      trace msg 
      raise msg unless @raise
    end

  end
end
