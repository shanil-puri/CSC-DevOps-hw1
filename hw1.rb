#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'droplet_kit'
require 'aws-sdk-v1'

class Deployment
    @region = 'nyc3';
    @droplet_size = '512mb';
    @droplet_image = "ubuntu-14-04-x64";
    @droplet_name = "CSC-DevOps-HW1"
    @droplet = '';
    @client = '';
    @aws_access_key = '';
    @aws_secret_key = '';
    @ec2 = '';
    @ec2_instance = ''

    def self.populate_keys
        file = File.read('access_keys.json');
        keys_arr = JSON.parse(file);
        @token = keys_arr["digoc_token"];
        @aws_access_key = keys_arr["AccessKeyId"];
        @aws_sercret_key = keys_arr["SecretAccessKey"];
        @aws_size = 't2.micro'
        @key_pair_name       = 'aws_hw1'                         # key pair name
        @private_key_file    = "aws_hw1.pem" # path to your private key
        @security_group_name = 'hw1'                            # security group name
        @instance_type       = 't2.micro'
    end

    def self.create_dig_droplet
        @client = DropletKit::Client.new(access_token: @token);
        @droplet = DropletKit::Droplet.new(
                                                    name: @droplet_name, 
                                                    region: @region, 
                                                    size: @droplet_size, 
                                                    image: @droplet_image);
        @droplet = @client.droplets.create(@droplet)
    end

    def self.delete_droplet
        @client.droplets.delete(id: @droplet.id);
    end

    def self.create_aws_instance
        AWS.config(
                    :access_key_id     => @aws_access_key, 
                    :secret_access_key => @aws_sercret_key
                )
        @ec2                 = AWS::EC2.new.regions['us-west-2']
        key_pair = @ec2.key_pairs[@key_pair_name]
        security_group = @ec2.security_groups.find{|sg| sg.name == @security_group_name }
        @ec2_instance = @ec2.instances.create(
                                            :image_id => "ami-c9fbe4f9", 
                                            :instance_type   => @instance_type, 
                                            :count => 1,
                                            :security_groups => security_group, 
                                            :key_pair => key_pair
                                        )
        sleep 1 until @ec2_instance.status != :pending

    end

    def self.get_dig_droplet_reservation
        @droplet = @client.droplets.find(id: @droplet.id)
        
        if @droplet.status == "active"
            return @droplet.networks["v4"][0]["ip_address"]
        end
        
        return nil;
    end

    def self.get_aws_reservation
        if @ec2_instance.status == :pending
            self.create_aws_instance
        end
        return @ec2_instance.ip_address
    end

    def self.create_inventory
        dropletIp = self.get_dig_droplet_reservation;
        while dropletIp.nil?
            sleep 30;
            dropletIp = self.get_dig_droplet_reservation;
        end

        printf "Digitalocean droplet created with IP: " + dropletIp
        
        awsIp = self.get_aws_reservation
        printf "AWS EC2 instance created with IP: " + awsIp

        digital_inv = "droplet ansible_ssh_host="+dropletIp+" ansible_ssh_user=root ansible_ssh_private_key_file=./digoc_kw.key\n"
        aws_inv = "aws ansible_ssh_host="+awsIp+" ansible_ssh_user=ubuntu ansible_ssh_private_key_file=./aws_hw1.pem"
        
        File.open('inventory', 'w') do |f|
            f2.puts digital_inv;
            f2.puts aws_inv;
        end
    end
    def self.ansible_deploy args
        self.populate_keys
        self.create_aws_instance
        self.create_dig_droplet

        if args == "inventory" 
            self.create_inventory
        elsif args == "deploy"
            self.create_inventory
            exec `ansible-playbook -i inventory playbook.yml`
        else
            printf "Wrong aruments supplied.";
        end
    end
end