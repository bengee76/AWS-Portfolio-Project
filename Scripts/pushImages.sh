#! /bin/sh

#script for pushing images to ECR

env=$ENVIRONMENT docker bake

aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com

docker tag cookie-$ENVIRONMENT/frontend:latest $ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/cookie-$ENVIRONMENT/frontend:latest
docker tag cookie-$ENVIRONMENT/backend:latest $ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/cookie-$ENVIRONMENT/backend:latest

docker push $ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/cookie-$ENVIRONMENT/frontend:latest
docker push $ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/cookie-$ENVIRONMENT/backend:latest