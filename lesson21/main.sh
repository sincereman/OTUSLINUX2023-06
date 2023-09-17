#!/bin/bash

# update prometheus binary

sudo wget https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz
tar -xvf prometheus-2.47.0.linux-amd64.tar.gz
sudo rm -rf prometheus-2.47.0.linux-amd64.tar.gz
sudo rm -rf ./ansible/roles/server/files/prometheus-latest-linux-amd64
mv prometheus-2.47.0.linux-amd64 ./ansible/roles/server/files/prometheus-latest-linux-amd64 -f


# update exporters binary
sudo wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
sudo tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz
sudo rm -rf node_exporter-1.6.1.linux-amd64.tar.gz
sudo rm -rf ./ansible/roles/client/files/node_exporter-latest-linux-amd64
sudo mv node_exporter-1.6.1.linux-amd64 ./ansible/roles/client/files/node_exporter-latest-linux-amd64 -f

cd vm
vagrant up
cd ..
cd ansible

ansible-playbook playbooks/server.yml
ansible-playbook playbooks/client.yml
ansible-playbook playbooks/updateserversnode.yml

