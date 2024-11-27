#!/bin/bash
sudo yum update -y
sudo yum install nginx -y
sudo yum install aws-cli -y

sudo systemctl start nginx
sudo systemctl enable nginx

sudo aws s3 cp s3://coockie-bucket-76/index.html /usr/share/nginx/html/index.html
sudo systemctl restart nginx