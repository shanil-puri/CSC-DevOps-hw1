# Homework 1
Deliverables
------------
1. Code => hw1.rb
2. Ansible Playbook =>  playbook.yml
3. Screencast =>  final_hw1_presentation.mov

Amazon EC2
-----------
Amazon Dynamo Db is a fast read-write hashing based no sql database by amazon. It is special in that it is elastically scalable and being a no sql database its is a high performance database.

Requirements
------------
Must have installed

1. Ruby 2.0 >
2. pip 
3. RVM

Dependencies
------------
1. rvm install "aws-sdk-v1"
2. rvm install "droplet_kit"

How to Run
----------
1. Clone this repo 

   ```
   git clone https://github.com/shanil-puri/CSC-DevOps-hw1.git
   ```
2. Create access_keys.json file as :

  ```
  {
    "AccessKeyId"    		:    <AWS Access key>,
    "SecretAccessKey"    	:    <AWS Secret Key>,
    "digoc_token"    		:    <Digitalocean Token>
  }

  ```
4. Generate Inventory by spinning instance on AWS and digitalocean

   ```
   ruby -r "./hw1.rb" -e "Deployment.ansible_deploy 'inventory'"
   ```
5. Deploy nginx on hosts from generated inventory

   ```
   ansible-playbook -i inventory playbook.yml
   ```

Screencast
----------
[screencast](https://github.com/shanil-puri/CSC-DevOps-hw1/blob/master/final_hw1_presentation.mov)
