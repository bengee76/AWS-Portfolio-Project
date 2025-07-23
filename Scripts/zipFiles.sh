#!/bin/bash
cd ../../Lambda
cp ../App/backend/Models/models.py .
pip install --target ./package sqlalchemy==2.0.41 PyMySQL==1.1.1
mkdir seed daily

cp -r package/* daily/
cp models.py daily/
cp index.py daily/
cp -r package/* seed/
cp models.py seed/
cp seed.py seed/

cd seed && zip -r ../seed.zip .
cd ../daily && zip -r ../daily.zip .
