FROM alpine:3.14.0
RUN apk add nginx
#config
COPY ./page/default.conf /etc/nginx/http.d/default.conf
# Страница приветствия сайта
COPY page/index.html /usr/share/nginx/html/
CMD ["nginx", "-g", "daemon off;"]