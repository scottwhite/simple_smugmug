require 'rubygems'
require 'spec'

RAILS_ENV = 'spec' unless Module.const_defined?('RAILS_ENV')



# def stub_config
#   config = {'spec'=>{'host'=>host,'port'=>port,'timeout'=>timeout,'pub_key'=>pub_key,'priv_key'=>priv_key, 'retry'=>1,
#     'use_ssl'=>use_ssl,
#     'api_path' => '/services/api/rest/1.2.2/'}}
#   SimpleSmugMug.const_set('CONFIG',config)
# end

def start_server
  server = Mongrel::HttpServer.new('0.0.0.0', 54321)
  server.register("/aws", FakeSoapHTTPService.new)
  server.run
  sleep 2
  server
end