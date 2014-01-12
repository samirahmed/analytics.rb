class Analytics 
   class << self
    require  'net/http'
    require  'pp'
    require  'socket'
    require  'open-uri'
    require  'securerandom'

    class AnalyticsError < StandardError 
    end

    attr_accessor :debug, :raising,                                        # Gem Settings
                  :app_name, :client_id, :tracking_id, :protocol_version,  # G.A Required
                  :anonymize_ip, :session, :app_version                    # G.A Optional

    def configure(tid, appname,  opts = {})
     
      # clear existing configuration and reset
      instance_variables.each{ |v| instance_variable_set(v,nil) }

      # set defaults
      @raise = false
      @debug = false
      @client_id = SecureRandom.uuid()
      @protocol_version = '1'
      
      # set tid and app name explicitly and all remaining opts
      @tracking_id = tid
      @app_name = appname
      
      opts.each do |key,value|
        return unless self.respond_to?(key.to_s+"=")
        self.send(key.to_s+"=",value)
      end
      
      # Return the configuration hash
      globals 

    end

    [:event, :exception].each do |method|
      
      define_method("#{method}!") do |opts = {}| 
        execute( opts.merge hit_type: method.to_s )
      end

      define_method(method) do |opts = {}|
        begin
          self.send("#{method}!", opts)
        rescue Exception => e
          trace e.message, e.backtrace.inspect
        end
      end
    end
    
    def globals
      Hash[instance_variables.map{ |name| [name[1..-1].to_sym, instance_variable_get(name)]}]
    end

    private

    GLOBAL_OPT = {
      :anonymize_ip =>     { key: 'aip', value: '1' },
      :app_name =>         { key: 'an',  byte: 100, required: true },
      :app_version =>      { key: 'av',  byte: 100 },
      :client_id =>        { key: 'cid', required: true },
      :non_interaction =>  { key: 'ni',  value: '1' },
      :protocol_version => { key: 'v',   value: '1', required: true },
      :session =>          { key: 'sc',  nominal: ['start', 'end'] },
      :tracking_id =>      { key: 'tid', required: true },
    }

    EXCEPTION_OPT = {
      :description => { key: 'exd', byte: 150 },
      :fatal? =>    { key: 'exf', value: '1' , binary: true},
      :hit_type =>  { key: 't',   value: 'exception' }
    }

    EVENT_OPT = {
      :action =>   { key: 'ea',  byte: 500, required: true },
      :category => { key: 'ec',  byte: 150, required: true },
      :hit_type => { key: 't',   value: 'event'  },
      :label =>    { key: 'el',  byte: 500 },
      :value =>    { key: 'ev' }
    }

    def extract( opt, value)
      
      return {} if opt.nil? || opt[:key].nil?

      # Get the option key
      _key = opt[:key]

      # Check if binary parameter
      if opt[:binary] && value
          return {_key =>  '1' }
      elsif opt[:binary]
          return {}
      end
     
      # parse non binary parameter
      _value = value || ( opt[:value] if opt[:required] )

      result = {}

      if _value.nil?
        err "nil value for required parameter #{_key}" if opt[:required]
      elsif opt[:byte] && _value.bytesize > opt[:byte]
        err "#{_value} is larger than #{opt[:byte]} bytes"
      elsif opt[:nominal] && !opt[:nominal].include?(_value) 
        err "#{_key} must be on of #{opt[:nominal].inspect} - not #{_nominal}"
      elsif _value
        result = {_key => _value}
      end

      result
    end
    
    def transform(original, options)
      original.inject({}) do |result, (key, value)|
        result.merge!(extract options[key] , value )
      end
    end
   
    def execute(opts)
      
      err "Invalid TrackingId" unless @tracking_id && (@tracking_id =~ /UA-\w{4,8}-\w{1,2}/)

      query = globals.merge opts
      query = transform( query, GLOBAL_OPT )

      case opts[:hit_type]
        when "event"
          query.merge! transform( opts, EVENT_OPT)
        when "exception"
          query.merge! transform( opts, EXCEPTION_OPT)
      end
      
      trace query.inspect 
      
      thread = Thread.new do
        
        uri = URI::HTTP.build({
          :host => "www.google-analytics.com",
          :path => "/collect",
          :query => Hash[query.sort].map{|k,v| "#{k}=#{URI.escape(v.to_s)}"}.join('&')
        })

        trace uri.to_s 
        resp = Net::HTTP.get_response uri
        
        trace resp.code
        
        Thread.current[:response] = resp 
      end
      
      thread
    end

    def trace *msg
      msg.each{|line| pp line } if @debug
    end

    def err msg 
      trace msg 
      fail AnalyticsError, msg unless @raise
    end

  end
end
