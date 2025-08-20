#!/bin/bash
cd ../../Lambda
cp ../App/backend/app/models.py .
cp ../App/backend/app/extensions.py .
pip install --target ./package sqlalchemy==2.0.41 PyMySQL==1.1.1
mkdir seed daily

cp -r package/* daily/
cp extensions.py models.py index.py daily/
cp -r package/* seed/
cp  extensions.py models.py seed.py seed/

cd seed && zip -r ../seed.zip .
cd ../daily && zip -r ../daily.zip .
