FROM php:7.1.15-cli-jessie

WORKDIR /usr/src/clearinghouse/
COPY public /usr/src/clearinghouse/public
COPY conf/production /usr/src/clearinghouse/conf

WORKDIR /usr/src/clearinghouse/public

CMD exec php -S snares.humlab.umu.se:8000 -t .

EXPOSE 8000
