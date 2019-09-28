require 'json'
require 'open3'
require 'tty-prompt'
require_relative 'exosuit/configuration'
require_relative 'exosuit/key_pair'
require_relative 'exosuit/instance'

module Exosuit
  def self.config
    Configuration.new
  end

  def self.launch_instance
    Instance.launch(self.key_pair)
  end

  def self.key_pair
    if config.values['key_pair'] && config.values['key_pair']['path']
      KeyPair.new(
        config.values['key_pair']['name'],
        config.values['key_pair']['path']
      )
    else
      generate_key_pair
    end
  end

  def self.generate_key_pair
    KeyPair.new.save.tap do |key_pair|
      config.update_key_pair(name: key_pair.name, path: key_pair.filename)
      puts "Successfully created new key pair at #{key_pair.filename}"
    end
  end

  def self.dns_names
    command = "aws ec2 describe-instances --filters Name=instance-state-name,Values=running --profile=#{Exosuit.config.values['aws_profile_name']}"
    response, _, _ = Open3.capture3(command)

    JSON.parse(response)['Reservations'].map do |data|
      data['Instances'][0]['PublicDnsName']
    end
  end

  def self.ssh
    prompt = TTY::Prompt.new
    dns_name = prompt.select('Which instance?', dns_names)

    command = "ssh -i #{config.values['key_pair']['path']} -o StrictHostKeychecking=no ubuntu@#{dns_name}"
    puts command
    system(command)
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
