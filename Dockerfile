FROM php:7.3-fpm-alpine

WORKDIR /var/www/html

COPY --from=composer /usr/bin/composer /usr/bin/composer

ADD . .

RUN composer install --no-dev