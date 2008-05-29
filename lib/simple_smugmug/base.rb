module SimpleSmugMug
  # Class that handles the communications 
  class Base
    attr_accessor :host, :port, :api_path, :pub_key, :priv_key, :timeout, :retry, :use_ssl
    
    def initialize
      load_config
      @public_key_param = "APIKey=#{@pub_key}"
      @http = setup_http
    end
    def load_config
      @host = CONFIG[RAILS_ENV]['host']
      @port = CONFIG[RAILS_ENV]['port']
      @pub_key = CONFIG[RAILS_ENV]['pub_key']
      @priv_key = CONFIG[RAILS_ENV]['priv_key']
      @retry = CONFIG[RAILS_ENV]['retry']
      @timeout = CONFIG[RAILS_ENV]['timeout']
      @api_path = CONFIG[RAILS_ENV]['api_path']
    end
    
    # SEtup the session for further API calls
    # response should
    # <?xml version="1.0" encoding="utf-8"?>
    # <rsp stat="ok"><method>smugmug.login.anonymously</method><login><session id="6282ceea21b23f455d931c2603f06cef"></session></login></rsp>
    def setup_session
      method = 'smugmug.login.anonymously'
      response = ''
      begin
        xml = send_request(["method=#{method}"])
        logger.debug("setup_session: xml is #{xml}")
	      doc = Hpricot::XML(xml)
	      (doc/'Session').first.get_attribute('id')
      rescue Exception => e
        logger.error("setup_session: ugh it barfed, #{e.message}")
        raise SetupSessionError.new("unable to setup a session")
      end
    end

    def send_request(params)
      logger.debug("send_request: entry")
      data = nil
      s_time = Time.now
      begin
        count = (count)?+1:0
        #build path
        path = build_url_request(params)
        response,data = @http.start{|h_session|
          h_session.get2(path)
        }
        unless response.is_a?(Net::HTTPSuccess)
          raise InvalidResponse.new("Did not get a valid response, #{response.inspect}")
        end
        
        # data = open(url)
        # data = data.read unless data.nil?
      rescue Exception => e
        logger.error("send_request: error is #{e.message}")
        if [Timeout::Error].include?(e.class)
          retry if count < @retry
        end
        raise e
      end
      delta = Time.now - s_time
      logger.debug("send_request: time taken #{delta}")
      data
    end    
  
    private
    def encode_params(raw_params)
      raw_params.map{|item|
        a = item.split('=',2)
        [a[0],CGI::escape(a[1])].join('=')
        }
    end
  
  
    # Build the url request to send
    def build_url_request(params)
      logger.debug("build_url_request: params #{params.inspect}")
      #add constants
      #add key
      params << @public_key_param    
      # need to encode rest of the values
      encoded = encode_params(params)
      #encode the URL
      url = @api_path + '?' +encoded.join('&')
      logger.debug("build_url_request: url is #{url}")
      url
    end
  
  
    def setup_http
      logger.debug("setup_http: host: #{host}, port:#{port}")
      http = Net::HTTP.new(@host,@port)
      if @port.to_i == 443
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.ssl_timeout = @timeout
      end
      http.open_timeout =@timeout      
      http
    end
  end
end


