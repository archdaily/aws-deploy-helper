require  'base64'
require  'open-uri'
require  'yaml'
require  'fog'

class AWSSite
  class NoELBError < Exception; end

  attr_accessor :elb, :asg, :compute, :main_asg

  def initialize(site_name)
    @config = YAML.load(File.open("#{File.dirname(__FILE__)}/../config/config.yml"))
    credentials = {
      aws_access_key_id: @config['aws']['access_key_id'],
      aws_secret_access_key: @config['aws']['secret_access_key'],
      region: @config['sites'][site_name]['region']
    }
    @main_asg = Fog::AWS::AutoScaling.new(credentials)
    @elb = initialize_elb(credentials, @config['sites'][site_name]['elb'])

    raise AWSSite::NoELBError unless @elb != nil

    @asg = initialize_asg(@main_asg, @elb.id)
    
    credentials[:provider] = 'AWS'
    @compute = Fog::Compute.new credentials
    @credentials = credentials
  end

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
      if server = @compute.servers.get(instance[:id])
        instance.merge!(instance_hash(server))
        instance
      else
        nil
      end
    end.compact.sort {|x,y| x[:id] <=> y[:id] }
  end


  private
  
  def initialize_elb(credentials, dns_name)
    Fog::AWS::ELB.new(credentials).load_balancers.select do |elb|
      elb.dns_name == dns_name
    end.first
  end

  def initialize_asg(main_asg, elb_id)
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