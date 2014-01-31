$:.unshift File.dirname(__FILE__)
require 'lib/awssite.rb'
require 'yaml'
require 'tempfile'

begin
  @config = YAML.load(File.open("#{File.dirname(__FILE__)}/config/config.yml")) 
  ssh_config = Tempfile.new('ssh_config')
  cap_config = Tempfile.new('cap_config')
  cap_config.write("sites:\n")
  @config['sites'].each_pair do |site_name,v|
    puts "site: #{site_name}"
    cap_config.write("  #{site_name}:\n")
    site = AWSSite.new (site_name)
    site.instances.each_with_index do |instance, index|
      puts " - #{instance[:hostname]} (#{instance[:id]})"

      ssh_config.write("Host #{site_name}_#{index+1}\n")
      ssh_config.write("  Hostname #{instance[:hostname]}\n")
      ssh_config.write("  User ubuntu\n")
      ssh_config.write("  IdentityFile #{@config["sites"][site_name]["keys"]}\n")
      ssh_config.write("  StrictHostKeyChecking no\n\n")

      cap_config.write("   - #{site_name}_#{index+1}\n")
    end
  end
  ssh_config.write("# #{Time.now}\n")
  ssh_config.rewind
  cap_config.rewind
  FileUtils.cp(ssh_config.path, '/tmp/new_ssh_config.txt')
  FileUtils.cp(cap_config.path, '/tmp/new_cap_config.yml')
  FileUtils.cp('/tmp/new_ssh_config.txt', @config['path']['ssh_config_file'])
  FileUtils.cp('/tmp/new_cap_config.yml', @config['path']['cap_config_file'])
  ssh_config.close
  cap_config.close
rescue Exception => e
  puts e
end
