module SimpleSmugMug
  
  class Album
    attr_accessor :id, :title, :key, :category, :images, :pub_key, :session_id
    
    def initialize(api_key=nil, session_id=nil)
      @api_key = api_key if api_key
      @session_id = session_id if session_id
    end
    
    def images
      Image.find(:api_key=>@pub_key,:session_id=>@session_id,:album_id=>@id, :album_key=>@key)
    end
    
    def image_urls
      Image.find_urls(:api_key=>@pub_key,:session_id=>@session_id,:album_id=>@id, :album_key=>@key)
    end
    
    class << self
      def find(options={:api_key=>nil,:smug_user=>nil,:nickname=>nil,:heavy=>false,:site_password=>nil,:session_id=>nil})
        # *  SessionID - string.
        # * NickName - string (optional).
        # * Heavy - boolean (optional).
        # * SitePassword - string (optional).
        
        method = 'smugmug.albums.get'
        base = Base.new(options[:api_key])
        base.session_id = options[:session_id]
        base.smug_user = options[:smug_user] if options[:smug_user]
        session_id = options[:session_id] || base.setup_session
        xml = base.send_request_with_session(["method=#{method}"])
        doc = Hpricot::XML(xml)
        logger.debug("find: result is #{doc}")        
        albums = load_albums(doc,options[:api_key],session_id)
        albums
      end
      
      private
      def load_albums(doc,api_key,session_id)
        albums = (doc/'Album').map{|e|
          al = Album.new(api_key,session_id)
          al.id = e.get_attribute('id')
          al.title = e.get_attribute('Title')
          al.key = e.get_attribute('Key')
          cat = (doc/'Category').first
          al.category = Category.new(cat.get_attribute('id'),cat.get_attribute('Name'))
          al
        }
      end
    end
  end
  
  class Category
    attr_accessor :name, :id
    def initialize(id,name)
      @id = id
      @name = name
    end
  end
end