FROM nginx:alpine


COPY nginx.conf /etc/nginx/nginx.conf
COPY static /var/www/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]