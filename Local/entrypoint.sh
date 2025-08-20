#! /bin/sh

echo "*/2 * * * * python3 /app/index.py" > /etc/crontabs/root

python seed.py
echo "Database seeded and users were created"

crond -f -l 2