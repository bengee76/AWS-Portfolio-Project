FROM python:3.13-alpine

COPY *.py /app/
COPY requirements.txt /app/
COPY entrypoint.sh /app/

WORKDIR /app

RUN chmod +x /app/entrypoint.sh
RUN pip install -r requirements.txt cryptography

ENTRYPOINT ["/app/entrypoint.sh"]