#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'droplet_kit'
require 'ansible_module'
require 'aws-sdk'

class Deployment < AnsibleModule
    @region = 'nyc3';
    @droplet_size = '512mb';
    @droplet_image = "ubuntu-14-04-x64";
    @droplet_name = "CSC-DevOps-HW1"
    @droplet = '';
    @client = '';
    @aws_access_key = '';
    @aws_secret_key = '';

    def self.populate_keys
        file = File.read('file-name-to-be-read.json');
        keys_arr = JSON.parse(file);
        @token = keys_arr["digoc_token"];
        @aws_access_key = keys_arr["AccessKeyId"];
        @aws_sercret_key = keys_arr["SecretAccessKey"];
        @aws_size = 't2.micro'
    end

    def self.create_dig_droplet
        @client = DropletKit::Client.new(access_token: @token);
        @droplet = JSON.parse(DropletKit::Droplet.new(name: droplet_name, region: region, size: droplet_size, image: droplet_image, user_data: userdata))["droplet"];
        @client.droplets.create(@droplet)
    end

    def self.delete_droplet
        dropletId = @droplet["id"];
        @client.droplets.delete(id: dropletId);
    end

    def self.create_aws_instance
        Aws.config.update({
                region: 'us-west-2',
                credentials: Aws::Credentials.new(@aws_access_key, @aws_sercret_key),
            })

        ec2 = Aws::EC2::Resource.new(region:'us-west-2', credentials: credentials)
        ec2.instances.create(   
                                :image_id => 'ami-11d68a54',
                                :instance_type => @aws_size,
                                :count => 1, 
                                :security_groups => 'sg-20fb7744', 
                                :key_pair => ec2.key_pairs['spuri3']
                            ) 
    end

    def self.get_dig_droplet_reservation
        dropletId = @droplet["id"];
        action = JSON.parse(@client.droplet_actions.reboot(id: dropletId))["action"];
        action_status = action["status"];
        
        while action_status != "completed"
            print "Droplet not ready, will retry after 30 sec";
            sleep(30);
            action_status = JSON.parse(@client.droplet_actions.find(id: action["id"]))["action"]["status"];
        end
        droplet_ip = JSON.parse(@client.droplets.find(id: @droplet["id"]))["droplet"]["networks"]["v4"];
        return droplet_ip;
    end

    def self.get_aws_reservation
        aws_ip = ""
        return aws_ip
    end

    def self.create_inventory
        dropletIp = self.get_dig_droplet_reservation;
        printf "Digitalocean droplet created with IP: " + dropletIp
        
        awsIp = self.get_aws_reservation
        printf "AWS EC2 instance created with IP: " + awsIp

        digital_inv = "droplet ansible_ssh_host="+dropletIp+" ansible_ssh_user=root ansible_ssh_private_key_file=./keys/hw1.key\n"
        aws_inv = "aws ansible_ssh_host="+awsIp+" ansible_ssh_user=ubuntu ansible_ssh_private_key_file=./keys/aws_hw1.key"
        
        File.open('inventory', 'w') do |f|
            f2.puts digital_inv;
            f2.puts aws_inv;
        end
    end
    def main args
        self.create_aws_instance
        self.create_dig_droplet

        if args == "inventory" 
            self.create_inventory
        elsif args == "deploy"
            exec `ansible-playbook -i inventory playbook.yml`
        end
    end
end