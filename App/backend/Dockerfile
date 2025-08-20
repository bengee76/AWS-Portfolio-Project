FROM python:3.13-alpine

COPY . /app
WORKDIR /app

RUN pip install --no-cache-dir -r requirements.txt
RUN chmod +x entrypoint.sh

EXPOSE 5000

CMD ["/app/entrypoint.sh"]