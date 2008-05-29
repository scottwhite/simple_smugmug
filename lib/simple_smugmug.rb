# SimpleSmugmug
require 'rubygems'
require 'hpricot'
require 'net/https'
require 'yaml'
require 'logger'
require 'cgi'
require File.dirname(__FILE__) + '/simple_smugmug/error'
require File.dirname(__FILE__) + '/simple_smugmug/base'
# namespace
module SimpleSmugMug
  
  CONFIG = YAML::load(File.open("#{RAILS_ROOT}/config/simple_smugmug.yml"))
  
end
def logger
  @logger ||= if Module.constants.include?('RAILS_DEFAULT_LOGGER')
                RAILS_DEFAULT_LOGGER
              else
                Logger.new('simple_smugmug.log')
              end
end
