require File.dirname(__FILE__) + '/spec_helper'
require 'time'
require File.dirname(__FILE__) + '/../lib/simple_smugmug'

KEY = YAML::load(open( File.dirname(__FILE__)+'/keys.yml'))
LOGIN = YAML::load(open( File.dirname(__FILE__)+'/login.yml'))

describe "General API gig" do
  before(:each) do

  end
  it "should load a config file for communication" do
    SimpleSmugMug::CONFIG.should_not be_nil
    base = SimpleSmugMug::Base.new(KEY['pub_key'])
    base.port.should == 443
    base.host.should == 'api.smugmug.com'
  end
end

describe "API for login" do
  before(:each) do

  end
  it "should login with key" do
    base = SimpleSmugMug::Base.new(KEY['pub_key'])
    sessionid = base.setup_session
    sessionid.should_not be_nil
  end
  
  it "should login with key and username/password" do
    base = SimpleSmugMug::Base.new(KEY['pub_key'])
    base.smug_user.email = LOGIN['username']
    base.smug_user.password = LOGIN['password']
    sessionid = base.setup_session
    sessionid.should_not be_nil
    base.smug_user.nickname.should == 'mochafiend'
  end
  it "should barf if no key found" do
    base = SimpleSmugMug::Base.new(nil)
    lambda{base.setup_session}.should raise_error(SimpleSmugMug::SetupSessionError)
  end
  
end

#  1.2.1 and in particular:
# 
# smugmug.albums.get
# smugmug.images.get
# smugmug.images.getURLs


describe "API albums" do
  before(:each) do
    
  end
  
  it "should return a list of albums" do
    user = SimpleSmugMug::User.new
    user.email = LOGIN['username']
    user.password = LOGIN['password']
    albums = SimpleSmugMug::Album.find(:api_key=>KEY['pub_key'],:smug_user=>user)
    # albums = SimpleSmugMug::Album.find(:api_key=>KEY['pub_key'])    
    albums.should have_at_least(1).item
  end
end

describe "API images" do
  before(:each) do
    @user = SimpleSmugMug::User.new
    @user.email = LOGIN['username']
    @user.password = LOGIN['password']
    albums = SimpleSmugMug::Album.find(:api_key=>KEY['pub_key'],:smug_user=>@user)
    @album = albums.select{|a| a.key == 't5bJa'}.first
  end
    it "should return a list of images" do
      @album.images.should have_at_least(1).item
    end
    
    it "should return image info" do
      image = @album.images.first
      image.get_info
      image.file_name.should_not be_nil
      image.height.should > 0
      image.width.should > 0
      image.date.should > Time.parse('2000-01-01')
      image.md5sum.should_not be_nil
      image.format.should_not be_nil
      image.position.should == 1
      image.urls.tiny.should_not be_nil
      image.urls.thumb.should_not be_nil
      image.urls.large.should_not be_nil
      image.urls.original.should_not be_nil

    end
    
    it "should return a image URLs" do
      urls = @album.images.first.urls
      urls.should_not be_nil
      urls.tiny.should_not be_nil
      urls.thumb.should_not be_nil
      urls.large.should_not be_nil
      urls.original.should_not be_nil
    end
    
    it "should retrieve images for a specific album" do
      album_id = @album.id
      album_key = @album.key
      images = SimpleSmugMug::Image.find(:api_key=>KEY['pub_key'],:smug_user=>@user,:session_id=>@album.session_id,:album_id=>album_id,:album_key=>album_key)
      images.should_not be_empty
      images.should have_at_least(1).item
    end
end    
    
describe "Usering user object convenience methods" do
  before(:each) do
    @user = SimpleSmugMug::User.new
    @user.email = LOGIN['username']
    @user.password = LOGIN['password']
    @user.api_key = KEY['pub_key']
  end
  
  it "should find all albums for a user" do
    albums = @user.albums
    albums.should have_at_least(1).item
  end
  
  it "should find images for an album" do
    album = @user.albums.first
    images = @user.images_for_album(album.id, album.key)
    images.should have_at_least(1).item
    images.first.urls.thumb.should_not be_nil
  end
end