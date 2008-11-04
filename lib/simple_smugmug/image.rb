module SimpleSmugMug
  class Image
    attr_accessor :id, :key, :api_key, :session_id, :urls
    
    def initialize(api_key=nil,session_id=nil)
      @api_key = api_key
      @session_id = session_id
    end
    
    def urls
      # AlbumID
      # *  int ImageID
      # * int TemplateID
      #       o optional, specifies which Style to build the AlbumURL with. Default: 3
      #       o Possible values:
      #             + Elegant: 3
      #             + Traditional: 4
      #             + All Thumbs: 7
      #             + Slideshow: 8
      #             + Journal: 9
      # 
      # * String Password optional
      # * String SitePassword optional
      # * string ImageKey
      unless @urls
        method = 'smugmug.images.getURLs'
        base = Base.new(@api_key)
        base.session_id = @session_id
        params =["method=#{method}"]
        params << "ImageID=#{@id}"
        params << "ImageKey=#{@key}"
        xml = base.send_request_with_session(params)
        doc = Hpricot::XML(xml)
        logger.debug("urls: result is #{doc}")        
        @urls = load_urls(doc)
      end
    end
    
    
    class << self

      def find(options={:api_key=>nil,:session_id=>nil,:album_id=>nil, :album_key=>nil})        
        # * SessionID - string.
        # * AlbumID - integer.
        # * Heavy - boolean (optional).
        # * Password - string (optional).
        # * SitePassword - string (optional).
        # * AlbumKey - string.
        
        method = 'smugmug.images.get'
        base = Base.new(options[:api_key])
        base.session_id = options[:session_id]
        params =["method=#{method}"]
        params << "AlbumID=#{options[:album_id]}"
        params << "AlbumKey=#{options[:album_key]}"
        xml = base.send_request_with_session(params)
        doc = Hpricot::XML(xml)
        logger.debug("find: result is #{doc}")        
        load_images(doc,options[:api_key],options[:session_id])
      end
      
      private
      def load_images(doc,api_key,session_id)
        (doc/'Image').map{|e|
          image = Image.new(api_key,session_id)
          image.id = e.get_attribute('id')
          image.key = e.get_attribute('Key')
          image
        }
      end      
    end
    
    private
      def load_urls(doc)
        image_url= (doc/'Image').each{|e|
          url = ImageUrl.new
          url.id = e.get_attribute('id')
          url.key = e.get_attribute('Key')
          url.small = e.get_attribute('SmallURL')
          url.original = e.get_attribute('OriginalURL')
          url.x2large = e.get_attribute('X2LargeURL')
          url.x3large = e.get_attribute('X3LargeURL')
          url.xlarge = e.get_attribute('XLargeURL')
          url.thumb = e.get_attribute('ThumbURL')
          url.tiny = e.get_attribute('TinyURL')
          url.medium = e.get_attribute('MediumURL')
          url.large = e.get_attribute('LargeURL')
          url
        }
        image_url
      end
    
  end
  
  class ImageUrl
    attr_accessor :small, :original, :x2large, :x3large, :xlarge, :id, :thumb, :tiny, :medium, :large, :key
  end
end