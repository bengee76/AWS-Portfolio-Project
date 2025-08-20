#!/bin/sh

if [ "$ENVIRONMENT" = "development" ]; then
    echo "Development mode"
    exec flask run --host=0.0.0 --port=5000 --debug --no-reload
else
    echo "Production mode"
    exec "gunicorn -w 3 --bind 0.0.0.0:5000 run:app"
fi