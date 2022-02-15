FROM ruby:3.0.3-alpine3.14
LABEL version="1.0"
LABEL maintainer="Kiagus Arief Adriansyah <kadriansyah@gmail.com>"

ENV BUILD_PACKAGES="build-base linux-headers libc6-compat curl-dev ruby-dev zlib-dev libxml2-dev libxslt-dev boost-dev pcre-dev" \
    SUPPORT_PACKAGES="curl tzdata wget zlib openssl" \
    RAILS_PACKAGES="nodejs npm" \
    RAILS_VERSION="6.1.4.6"

RUN apk --update --upgrade add $BUILD_PACKAGES $SUPPORT_PACKAGES $RAILS_PACKAGES
RUN gem install bundler && npm install --global yarn \
    && gem install rails --version "$RAILS_VERSION" \
    && echo 'gem: --no-document' >> ~/.gemrc \
    && cp ~/.gemrc /etc/gemrc \
    && chmod uog+r /etc/gemrc \
    && gem install passenger \
    && passenger-install-nginx-module \
    # cleanup and settings
    && find / -type f -iname \*.apk-new -delete \
    && rm -rf /var/cache/apk/* \
    && rm -rf /usr/lib/lib/ruby/gems/*/cache/* \
    && rm -rf ~/.gem \
    && rm -rf /var/cache/apk/* \
    # force uninstall nokogiri to fix problem nokogiri load error
    # (https://nokogiri.org/tutorials/installing_nokogiri.html#cannot-load-such-file-nokogirinokogiri-loaderror)
    # reinstall using "bundle install"
    && gem uninstall nokogiri -I

# custom nginx.conf
COPY nginx.conf /opt/nginx/conf/
RUN mkdir /opt/nginx/sites-enabled && mkdir /opt/nginx/sites-available
COPY default /opt/nginx/sites-available/
RUN ln -s /opt/nginx/sites-available/default /opt/nginx/sites-enabled/default

# create "app" user \
RUN set -ex \
    && addgroup -g 9999 app \
    && adduser -u 9999 -G app -h /home/app -D app
ENV PATH=/opt/nginx/sbin:$PATH

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /opt/nginx/logs/access.log
RUN ln -sf /dev/stderr /opt/nginx/logs/error.log

EXPOSE 80 443
STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
