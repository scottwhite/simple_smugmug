module SimpleSmugMug
  # Class that handles the communications 
  class Base
    attr_accessor :host, :port, :api_path, :pub_key, :priv_key, :timeout, :retry, :use_ssl, :session_id, :smug_user
    
    def initialize(api_key,options={:retries=>nil, :timeout=>nil})
      load_config
      @retry = options[:retries] unless options[:retries].nil?
      @timeout = options[:timeout] unless options[:timeout].nil?
      @smug_user = User.new      
      @pub_key=api_key
      @public_key_param = "APIKey=#{@pub_key}"
      # @http = setup_http
    end
    
    def load_config
      @host = CONFIG['host']
      @port = CONFIG['port']
      @retry = CONFIG['retry']
      @timeout = CONFIG['timeout']
      @api_path = CONFIG['api_path']
    end
    
    # Setup the session for further API calls
    def setup_session
      @session_id ||= if @smug_user.email
                setup_session_with_username
              else 
                setup_session_anonymously
              end
    end
    
    def setup_session_anonymously
        setup_session_with ["method=smugmug.login.anonymously"]
    end
    
    # *  string APIKey
    # * string EmailAddress
    # * string Password
    
    def setup_session_with_username
      method = 'smugmug.login.withPassword'
      setup_session_with ["method=#{method}","EmailAddress=#{@smug_user.email}","Password=#{@smug_user.password}"]
    end
    
    def setup_session_with(request)
      begin
        xml = send_request(request)
        json = JSON.parse(xml)
        logger.debug("setup_session_with: xml is #{json}")
        # doc = Hpricot::XML(xml)
        
	      load_user(json["Login"]) unless json["Login"]["User"].nil?
        json["Login"]["Session"]["id"]
      rescue StandardError => e
        logger.error("setup_session_with: ugh it barfed, #{e.message}")
        raise SetupSessionError.new("unable to setup a session")
      end      
    end
    
    def send_request_with_session(params)
      params << "SessionID=#{@session_id}"
      send_request(params)
    end
    
    def send_request(params)
      logger.debug("send_request: entry")
      data = nil
      s_time = Time.now
      begin
        count = (count)?count+1:0
        #build path
        path = build_url_request(params)
        url = "https://#{@host}" + path
        response = Curl::Easy.perform(url) do |easy|
          easy.headers["User-Agent"] ='simple_smugmug v1.0'
          easy.timeout = @timeout
        end
        data = response.body_str
        # response,data = @http.start{|h_session|
        #   h_session.get2(path,{'user-agent'=>'simple_smugmug v1.0'})
        # }
        # unless response.is_a?(Net::HTTPSuccess)
        #   raise "Did not get a valid response, #{response.inspect}"
        # end
        
        # data = open(url)
        # data = data.read unless data.nil?
      rescue Timeout::Error => e
        logger.error("send_request: error is #{e.message}")
        retry if count < @retry
        raise e
      end
      delta = Time.now - s_time
      logger.debug("send_request: time taken #{delta}")
      data
    end    
  
    private

    def load_user(doc)
        # user = (doc/'User').first
        # @smug_user.user_id = user.get_attribute('id')
        # @smug_user.nickname = user.get_attribute('NickName')
        # login = (doc/'Login').first
        # @smug_user.password_hash = login.get_attribute('PasswordHash')
        # @smug_user.filesize_limit = login.get_attribute('FileSizeLimit')
        @smug_user.user_id = doc["User"]["id"]
        @smug_user.nickname = doc["User"]["NickName"]
        @smug_user.password_hash = doc['PasswordHash']
        @smug_user.filesize_limit = doc['FileSizeLimit']
    end
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
      easy = Curl::Easy.new
      easy.timeout = @timeout
      easy.url = if @port.to_i == 443
        "https://#{@host}"
      else
        "http://#{@host}"
      end
      easy.headers["User-Agent"] ='simple_smugmug v1.0'
      # http = Net::HTTP.new(@host,@port)
      # if @port.to_i == 443
      #   http.use_ssl = true
      #   http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      #   http.ssl_timeout = @timeout
      # end
      # http.open_timeout =@timeout      
      # http
      easy
    end
  end
end


