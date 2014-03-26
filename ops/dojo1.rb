require 'rubygems'
require 'fog'
require './config.rb'
require 'getoptlong'

opts = GetoptLong.new(
    ['--help', '-h', GetoptLong::NO_ARGUMENT],
    ['--count', '-c', GetoptLong::REQUIRED_ARGUMENT],
    ['--environment', '-e', GetoptLong::REQUIRED_ARGUMENT],
    ['--mock', '-m', GetoptLong::NO_ARGUMENT],
)

ENVIRONMENTS = %w(test pre live)

# set some defaults
count = 1
environment = 'test'
security_group_name = 'sg_ux_demo_site'
key_pair_name = 'ux-demo-site'

opts.each do |opt, arg|
  case opt
    when '--help'
      puts "specify --count <number> to start <number> instances. Defaults to #{count} "
      puts 'specify --mock to run using fog in mocking mode'
      puts "specify --environment #{ENVIRONMENTS.join('|')} to deploy. Defaults to #{environment}"
      exit 0

    when '--count'
      count = arg.to_i
      unless count.between?(1,4)
        puts 'That is not an allowed number of servers!'
        exit 1
      end

    when '--mock'
      Fog.mock!

    when '--environment'
      unless ENVIRONMENTS.include? arg
        p "Environment must be one of: #{ENVIRONMENTS}"
        exit 1
      end
      environment = arg

  end

end

compute = Fog::Compute.new(
    {:provider              => 'AWS',
     :aws_access_key_id     => @aws_access_key_id,
     :aws_secret_access_key => @aws_secret_access_key,
     :region                => @aws_region
    }
)

puts 'Using region: '+ compute.region
puts 'Collections available:' + compute.collections.to_s

puts 'checking security group...'
sec = compute.security_groups.get(security_group_name)
if sec.nil?
  sec = compute.security_groups.create(
      :name         => security_group_name,
      :description  => "security group for ux demo site"
  )
  sec.authorize_port_range(22..22)
  sec.authorize_port_range(80..80)
  puts 'created new sg: ' + sec.name
else
  puts 'sg already exists: ' + sec.name
end

puts 'checking keypair...'
keypair = compute.key_pairs.get(key_pair_name)
if keypair.nil?
  keypair = compute.key_pairs.create(:name => key_pair_name)
  puts 'created keypair: ' + keypair.name
  keypair.write
  puts 'written keypair to disk'
else
  puts 'keypair already exists: ' + keypair.name
end

puts 'templating the user-data:'
user_data = File.read(File.join(File.dirname(__FILE__), "user-data.erb"))
user_data = ERB.new(user_data).result(binding)
puts user_data

puts 'Creating server'
server = compute.servers.create( :image_id => @image_id_us_west_2,
                                 :flavor_id =>  'm1.small',
                                 :groups => security_group_name,
                                 :user_data => user_data,
                                 :key_name => key_pair_name)

server.wait_for { print '.'; ready? }
puts 'server ready'

puts "Public IP Address: #{server.public_ip_address}"
puts "Private IP Address: #{server.private_ip_address}"
puts "Instance id: #{server.id} "
puts "Instance id: #{server.availability_zone} "
puts "Security Group Ids: #{server.security_group_ids} "
puts "Tags : #{server.tags} "
