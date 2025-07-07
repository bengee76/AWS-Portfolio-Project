#! /bin/sh

yum -y update
yum install -y docker

systemctl start docker
systemctl enable docker

TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

ACCOUNT_ID=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .accountId)

aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com

docker pull $ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/coockie/backend:latest

docker run -e DB_DNS=${dbDns} -p 80:5000 $ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/coockie/backend:latest