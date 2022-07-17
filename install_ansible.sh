#!/bin/bash

sudo apt-get update
sudo apt install ansible -y
git clone https://github.com/marbew/tf-ub-web.git
sudo sed -i '/^#inventory.*  /s/^#//' /etc/ansible/ansible.cfg
sudo echo "localhost ansible_connection=local" >> /etc/ansbile/hosts
ansible-playbook Setup_Apache_on_EC2_with_Terraform/apache.yml 