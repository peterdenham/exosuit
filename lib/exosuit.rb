require 'json'
require 'open3'
require_relative 'exosuit/configuration'
require_relative 'exosuit/keypair'
require_relative 'exosuit/instance'

module Exosuit
  def self.config
    Configuration.new
  end

  def self.launch_instance
    Instance.launch(generate_keypair)
  end

  def self.generate_keypair
    Keypair.new.save.tap do |keypair|
      config.update_keypair(name: keypair.name, path: keypair.filename)
      puts "Successfully created new keypair at #{keypair.filename}"
    end
  end

  def self.dns_names
    command = "aws ec2 describe-instances --filters Name=instance-state-name,Values=running --profile=#{Exosuit.config.values['aws_profile_name']}"
    response, _, _ = Open3.capture3(command)

    JSON.parse(response)['Reservations'].map do |data|
      data['Instances'][0]['PublicDnsName']
    end
  end

  def self.help_text
    %(Usage:
  exo [command]

These are the commands you can use:
  launch                 Launch a new EC2 instance
  describe-instances     Alias for aws ec2 describe-instances
  dns                    List public DNS names for all EC2 instances
  ssh                    SSH into an EC2 instance)
  end
end
