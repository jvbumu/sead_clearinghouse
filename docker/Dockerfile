FROM php:7.1.15-cli-jessie

RUN apt-get update \
    && apt-get install -y \
       postgresql-server-dev-9.4

RUN echo "Installing PHP extensions" \
    && docker-php-ext-install -j$(nproc) pdo_pgsql

RUN apt-get remove -y \
       postgresql-server-dev-9.4

RUN mkdir -p /usr/src/clearinghouse

WORKDIR /

COPY /public /usr/src/clearinghouse/public
COPY /conf /usr/src/clearinghouse/conf

RUN mkdir -p /usr/src/clearinghouse/public/api/api-cache

WORKDIR /usr/src/clearinghouse/public

EXPOSE 8060

CMD exec php -S 0.0.0.0:8060 -t .
