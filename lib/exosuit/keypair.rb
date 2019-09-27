require_relative './random_phrase'

module Exosuit
  class Keypair
    attr_accessor :name, :filename

    def initialize
      @name = RandomPhrase.generate
    end

    def filename
      "~/.ssh/#{@name}.pem"
    end

    def save
      command = %(
        aws ec2 create-key-pair --profile=#{Exosuit.config.values['aws_profile_name']} \
          --key-name #{@name} \
          --query 'KeyMaterial' \
          --output text > #{filename}
      )

      system(command)
      system("chmod 400 #{filename}")
      self
    end
  end
end
