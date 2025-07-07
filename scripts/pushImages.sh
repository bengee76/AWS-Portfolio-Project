#! /bin/sh

#script for pushing images to ECR

docker bake

docker tag coockie/frontend:latest $ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/coockie/frontend:latest
docker tag coockie/backend:latest $ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/coockie/backend:latest

docker push $ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/coockie/frontend:latest
docker push $ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/coockie/backend:latest