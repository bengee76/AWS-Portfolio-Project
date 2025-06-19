#! /bin/bash

VARR=$(aws ssm get-parameter --name "/coockie/password" --with-decryption| jq -r .Parameter.Value)

terraform plan -var "dbPassword=$VARR"
terraform apply -var "dbPassword=$VARR"