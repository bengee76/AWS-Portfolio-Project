#!/bin/bash
sudo yum update -y

sudo amazon-linux-extras install docker -y

sudo systemctl start docker
sudo systemctl enable docker #autostart

sudo docker pull coockie-repository/ #image from repository here

sudo docker run 

###ASK CLAUDE