module SimpleSmugMug
  # <Login PasswordHash="asdfasdf" AccountType="Standard" 
  # FileSizeLimit="asdfasdf"><Session id="asdfasd"/>
  # <User id="asdfsd" NickName="asdfasd" DisplayName="asdfasd"/>
  class User
    attr_accessor :user_id, :email, :password, :password_hash, :nickname, :filesize_limit, :api_key, :session_id
    
    def albums
      albums = Album.find(:api_key=>@api_key,:smug_user=>self,:session_id=>session_id)
    end
    
    def session_id
      @session_id ||= lambda{
        base = Base.new(api_key)
        base.smug_user = self
        base.setup_session
      }.call
    end
    
    def images_for_album(id,key)
      Image.find(:api_key=>@api_key,:session_id=>session_id,:album_id=>id,:album_key=>key)
    end
  end
  
end