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
        data = response.body_str unless response.nil?
      rescue Timeout::Error => e
        logger.error("send_request: error is #{e.message}")
        retry if count < @retry
        raise e
      end
      delta = Time.now - s_time
      logger.debug("send_request: time taken #{delta}")
      data
    end    
  
    def send_multi_request(queries =[])
      logger.debug("send_multi_request: entry")
      data = nil
      s_time = Time.now
      begin
        count = (count)?count+1:0
        host_path = "https://#{@host}"
        urls = queries.map do |params|
          host_path + build_url_request(params)
        end
        easy = Curl::Easy.new
        easy.headers["User-Agent"] ='simple_smugmug v1.0'
        easy.timeout = @timeout
        response = urls.map do |url|
            easy.url = url
            easy.perform
            easy.body_str
        end
        data = response unless response.nil?
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
  end
end


