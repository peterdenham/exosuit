require 'open3'
require 'json'

module Exosuit
  class Instance
    IMAGE_NAME = 'ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*'.freeze
    INSTANCE_TYPE = 't2.micro'.freeze

    def self.to_s(instance)
      tags = instance.tags.map { |t| "#{t.key}:#{t.value}" }.join(', ')
      tags = nil if tags == ''

      [
        instance.id,
        instance.state.name,
        tags,
        instance.public_dns_name
      ].compact.join("\n")
    end

    def self.launch(key_pair)
      Exosuit.ec2.create_instances(
        min_count: 1,
        max_count: 1,
        image_id: latest_ubuntu_ami.image_id,
        instance_type: INSTANCE_TYPE,
        key_name: key_pair.name
      ).first
    end

    def self.ssh(public_dns_name)
      command = %(
        ssh -i #{Exosuit.config.values['key_pair']['path']} \
          -o StrictHostKeychecking=no ubuntu@#{public_dns_name}
      )

      system(command)
    end

    def self.all
      Exosuit.ec2.instances
    end

    def self.running
      all.select { |i| i.state.name == 'running' }
    end

    def self.wait_for_ec2_instance(image_ids)
      Exosuit.ec2.wait_until(:instance_running, instance_ids: [Array(image_ids)])
      puts "#{image_ids} instance running"
    rescue Aws::Waiters::Errors::WaiterFailed => error
      puts "failed waiting for instance running: #{error.message}"
    end

    def self.latest_ubuntu_ami
      @latest_ubuntu_ami ||= Exosuit.ec2.images(
        executable_users: ['all'],
        filters: [{ name: 'name', values: [IMAGE_NAME] }]
      ).max_by(&:creation_date)
    end
  end
end
