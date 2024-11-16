#!/bin/bash
sudo yum update -y
sudo yum install nginx -y
sudo yum install aws-cli -y

sudo systemctl start nginx
sudo systemctl enable nginx

aws s3 cp s3://${aws_s3_bucket.myBucket.bucket}/index.html /usr/share/nginx/html/index.html
sudo systemctl restart nginx