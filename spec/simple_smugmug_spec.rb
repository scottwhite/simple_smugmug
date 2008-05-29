require File.dirname(__FILE__) + '/spec_helper'
require 'time'
require File.dirname(__FILE__) + '/../lib/simple_smugmug'

KEY = YAML::load(open( File.dirname(__FILE__)+'/keys.yml'))

describe "General API gig" do
  before(:each) do
    stub_config('mochafiend.smugmug.com',KEY['pub_key'], KEY['priv_key'])
  end
  it "should load a config file for communication" do
    SimpleSmugMug::CONFIG.should_not be_nil
    base = SimpleSmugMug::Base.new
    base.port.should == 443
    base.host.should == 'mochafiend.smugmug.com'
  end
end

describe "API for login" do
  before(:each) do
    stub_config('mochafiend.smugmug.com',KEY['pub_key'], KEY['priv_key'])
  end
  it "should login with key" do
    base = SimpleSmugMug::Base.new
    sessionid = base.setup_session
    sessionid.should_not be_nil
  end
  it "should barf if no key found" do
    pending "not implmented"
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
end