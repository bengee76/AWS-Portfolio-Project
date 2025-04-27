#! /bin/bash

sudo cp /home/bnmnx/Projects/AWS-Portfolio-Project/03-Database/App/nginx.conf /etc/nginx/nginx.conf

sudo systemctl reload nginx
sudo systemctl status nginx

#script for testing nginx on local machine

