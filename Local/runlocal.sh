#! /bin/sh

cp ../Lambda/*.py .
cp ../App/backend/app/models.py .
cp ../App/backend/app/extensions.py .
cp ../App/backend/requirements.txt .

docker compose build
docker compose up