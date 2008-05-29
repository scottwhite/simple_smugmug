require 'rubygems'
require 'spec'

RAILS_ROOT = File.dirname(__FILE__) + '/..' unless Module.const_defined?('RAILS_ROOT')
RAILS_ENV = 'spec' unless Module.const_defined?('RAILS_ENV')



def stub_config(host,pub_key,priv_key,port=443,timeout=10,use_ssl=true)
  config = {'spec'=>{'host'=>host,'port'=>port,'timeout'=>timeout,'pub_key'=>pub_key,'priv_key'=>priv_key, 'retry'=>1,
    'use_ssl'=>use_ssl,
    'api_path' => '/services/api/rest/1.2.2/'}}
  SimpleSmugMug.const_set('CONFIG',config)
  SimpleSmugMug.const_set('RAILS_ENV','spec') unless SimpleSmugMug.const_defined?('RAILS_ENV')
end

def start_server
  server = Mongrel::HttpServer.new('0.0.0.0', 54321)
  server.register("/aws", FakeSoapHTTPService.new)
  server.run
  sleep 2
  server
end