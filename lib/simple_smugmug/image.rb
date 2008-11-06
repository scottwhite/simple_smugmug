module SimpleSmugMug
  class Image
    attr_accessor :id, :key, :api_key, :session_id, :urls, :album,
                  :caption, :file_name, :keywords, :size, :height, :width, :position, :serial, :format, 
                  :date, :last_updated, :hidden, :watermark, :md5sum
    
    def initialize(api_key=nil,session_id=nil)
      @api_key = api_key
      @session_id = session_id
      @album = Album.new
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
      else
        @urls
      end
    end
    
    def get_info
      unless @info
        method = 'smugmug.images.getInfo'
        base = Base.new(@api_key)
        base.session_id = @session_id
        params =["method=#{method}"]
        params << "ImageID=#{@id}"
        params << "ImageKey=#{@key}"
        xml = base.send_request_with_session(params)
        doc = Hpricot::XML(xml)
        logger.debug("urls: result is #{doc}")
        @info = doc
        load_image(@info)
      else
        load_image(@info)
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
    def load_image(doc)
      (doc/'Album').each{|e|
        album.id = e.get_attribute("id")
        album.key = e.get_attribute("key")
        }
      (doc/'Image').each{|e|
        @id = e.get_attribute('id')
        @key = e.get_attribute('Key')
        @caption =e.get_attribute('Caption')
        @file_name = e.get_attribute('FileName')
        @width = e.get_attribute('Width').to_i
        @height = e.get_attribute('Height').to_i
        @last_updated = Time.parse(e.get_attribute('LastUpdated'))
        @watermark = e.get_attribute('WaterMark')
        @date = Time.parse(e.get_attribute('Date'))
        @hidden = e.get_attribute('Hidden')
        @keywords = e.get_attribute('Keywords')
        @size = e.get_attribute('Size').to_i
        @position = e.get_attribute('Position').to_i
        @serial = e.get_attribute('Serial')
        @format = e.get_attribute('Format')
        @md5sum = e.get_attribute('MD5Sum')
        
        @urls = ImageUrl.new
        @urls.small = e.get_attribute('SmallURL')
        @urls.original = e.get_attribute('OriginalURL')
        @urls.x2large = e.get_attribute('X2LargeURL')
        @urls.x3large = e.get_attribute('X3LargeURL')
        @urls.xlarge = e.get_attribute('XLargeURL')
        @urls.thumb = e.get_attribute('ThumbURL')
        @urls.tiny = e.get_attribute('TinyURL')
        @urls.medium = e.get_attribute('MediumURL')
        @urls.large = e.get_attribute('LargeURL')

      }
      
    end
      def load_urls(doc)
        url = ImageUrl.new
        (doc/'Image').each{|e|
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
        }
        url
      end
    
  end
  
  class ImageUrl
    attr_accessor :small, :original, :x2large, :x3large, :xlarge, :id, :thumb, :tiny, :medium, :large, :key
  end
  
  # <Image
  # FileName="DSC_0719.JPG" 
  # Keywords="" 
  # Hidden="0" 
  # Serial="0" 
  # Position="1" 
  # Size="1575810" 
  # Format="JPG" 
  # Date="2008-05-31 07:11:18" 
  # id="304553496" 
  # Watermark="0" 
  # LastUpdated="2008-05-31 07:11:55" 
  # Width="3008" 
  # MD5Sum="b1fbf9faec2855c3e39f03a74f713d25" 
  # Caption="" 
  # Height="2000" 
  # Key="ZAePP" 
  # <Album URL="http://mochafiend.smugmug.com/gallery/5062031_t5bJa#304553496_ZAePP" 
  # id="5062031" 
  # Key="t5bJa">
  # </Album>
  # </Image>
end