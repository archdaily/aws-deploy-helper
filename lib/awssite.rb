require  'base64'
require  'open-uri'
require  'yaml'
require  'fog'

class AWSSite
  class NoELBError < Exception; end

  #INSTANCE_TYPES = [['Micro', 't1.micro'], ['Small', 'm1.small'], ['Medium', 'c1.medium']]

  attr_accessor :elb, :asg, :record_name, :compute, :main_asg

  def initialize(site_name)
    @config = YAML.load(File.open("#{File.dirname(__FILE__)}/../config/config.yml"))
    #puts @config
    #puts "initialize site for site '#{site_name}' (elb: #{@config['sites'][site_name]['elb']})"
    credentials = {
      aws_access_key_id: @config['aws']['access_key_id'],
      aws_secret_access_key: @config['aws']['secret_access_key'],
      region: @config['sites'][site_name]['region']
    }
    @record_name = record_name
    @main_asg = Fog::AWS::AutoScaling.new(credentials)
    @elb = initialize_elb(credentials, @config['sites'][site_name]['elb'])

    raise AWSSite::NoELBError unless @elb != nil

    @asg = initialize_asg(@main_asg, @elb.id)
    
    credentials[:provider] = 'AWS'
    @compute = Fog::Compute.new credentials
    @credentials = credentials
  end

  # def asg_data
  #   {
  #     min_size: @asg.min_size,
  #     max_size: @asg.max_size,
  #     desired_size: @asg.desired_size
  #   }
  # end

  # def current_commit
  #   user_data['reference'] || 'Unknown'
  # end

  # def site_hostname
  #   user_data['site_hostname'] || 'Unknown'
  # end

  def instances
    registered_instances = @elb.instance_health.collect do |instance|
      { id: instance['InstanceId'], elb_instance_service_status: instance['State'] }
    end

    asg_instances = @asg.instances.collect do |instance|
      if instance.auto_scaling_group_name == @asg.id
        { id: instance.id, elb_instance_service_status: instance.life_cycle_state }
      end
    end.compact

    instances = (registered_instances + asg_instances).uniq {|instance| instance[:id] }
    instances.map! do |instance|
      if registered_instances.include?(instance)
        instance[:elb_registry_status] = 'Registered'
      else
        instance[:elb_registry_status] = 'Not Registered'
      end
      if server = @compute.servers.get(instance[:id])
        instance.merge!(instance_hash(server))
        instance
      else
        nil
      end
    end.compact.sort {|x,y| x[:id] <=> y[:id] }
  end

  # def user_data
  #   user_data_yaml = @asg.configuration.user_data
  #   begin
  #     YAML.load(Base64.decode64(user_data_yaml))
  #   rescue Exception => e
  #     Rails.logger.error "YAML ERROR: #{e.message}"
  #     raise e
  #   end
  # end

  # def toggle_instance_registration!(instance_id, elb_register_status)
  #   if elb_register_status == "Registered"
  #     @elb.deregister_instances([instance_id])
  #   else
  #     @elb.register_instances([instance_id])
  #   end
  # end

  # def reboot_instance!(instance_id)
  #   @compute.servers.get(instance_id).reboot
  # end

  # def terminate_instance!(instance_id)
  #   @compute.servers.get(instance_id).destroy
  # end

  # def terminate_instance_and_decrease_dc!(instance_id)
  #   if @asg.min_size == @asg.desired_capacity
  #     update_autoscaling_group({
  #       min_size: @asg.min_size - 1,
  #       max_size: @asg.max_size,
  #       desired_capacity: @asg.desired_capacity
  #     })
  #   end
  #   @main_asg.terminate_instance_in_auto_scaling_group(instance_id, true)
  # end

  # def instance_info(hostname)
  #   begin
  #     info_file = open("http://#{hostname}/wp-content/admd/site_info.json")
  #     json = JSON.parse(info_file.readlines.join(''))
  #     info_file.close
  #     json
  #   rescue Exception => e
  #     e.message + "\n\"http://#{hostname}/wp-content/admd/site_info.json\""
  #   end
  # end

  # def to_json
  #   {
  #     elb_name: @elb.dns_name,
  #     asg: {
  #       name: @asg.id,
  #       min_size: @asg.min_size,
  #       max_size: @asg.max_size,
  #       desired_capacity: @asg.desired_capacity,
  #       launch_config: {
  #         instance_type: @asg.configuration.instance_type,
  #         user_data: user_data
  #       },
  #     },
  #     instances: instances,
  #   }.to_json
  # end

  private
  
  def initialize_elb(credentials, dns_name)
    Fog::AWS::ELB.new(credentials).load_balancers.select do |elb|
      #puts "dns_name: #{elb.dns_name}"
      elb.dns_name == dns_name
    end.first
  end

  def initialize_asg(main_asg, elb_id)
    #puts "elb_id: #{elb_id}"
    main_asg.groups.each do |group|
      group.load_balancer_names.each { |name| return group if name == elb_id }
    end
    nil
  end

  def instance_hash(instance)
    {
      id: instance.id || '',
      hostname: instance.dns_name,
      ec2_status: instance.state,
      ip: instance.public_ip_address || '',
      commit: 'Loading info...',
      type: instance.flavor_id,
      created_at: instance.created_at,
      availability_zone: instance.availability_zone,
      name: instance.tags['Name'] || '',
    }
  end

end
