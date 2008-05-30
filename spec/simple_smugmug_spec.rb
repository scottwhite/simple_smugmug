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
    @album = albums.first
  end
    it "should return a list of images" do
      @album.images.should have_at_least(1).item
    end
    
    it "should return al ist or image URLs" do
      urls = @album.images.first.urls
      urls.should have_at_least(1).item
      urls.first.tiny.should_not be_nil
    end
end