# require 'yaml'
# require 'fog'
# class AWSMain
	
#   attr_accessor :dns, :config

#   def initialize
#     @config = YAML.load(File.open("#{File.dirname(__FILE__)}/../config/config.yml"))
#     @dns = Fog::DNS::AWS.new({
#       aws_access_key_id: @config['aws']['access_key_id'],
#       aws_secret_access_key: @config['aws']['secret_access_key'],
#     })
#     @sites = {}
#   end

#   def platforms
#     records = []
#     @dns.zones.each do |zone|
#       zone.records.each do |record|
#         if record.name == "www.#{zone.domain}" || record.name.match(/test/)
#           records << [record.name, record.value.first]
#         end
#       end
#     end
#     records
#   end

# end
