FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

COPY . /app
WORKDIR /app


RUN apt-get update && apt-get install -y python3 python3-pip tzdata \
    && ln -snf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime \
    && echo "Europe/Warsaw" > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata
    
RUN pip install -r requirements.txt

 CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]