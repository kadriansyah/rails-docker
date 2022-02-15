FROM ruby:3.0.3-alpine3.14
LABEL version="1.0"
LABEL maintainer="Kiagus Arief Adriansyah <kadriansyah@gmail.com>"

ENV BUILD_PACKAGES="build-base linux-headers curl-dev ruby-dev zlib-dev libxml2-dev libxslt-dev boost-dev pcre-dev" \
    SUPPORT_PACKAGES="curl tzdata wget zlib openssl" \
    RAILS_PACKAGES="nodejs npm" \
    RAILS_VERSION="6.1.4.6"

RUN apk --update --upgrade add $BUILD_PACKAGES $SUPPORT_PACKAGES $RAILS_PACKAGES
RUN gem install -N bundler && npm install --global yarn
RUN gem install -N nokogiri -- --use-system-libraries \
    && gem install -N rails --version "$RAILS_VERSION" \
    && echo 'gem: --no-document' >> ~/.gemrc \
    && cp ~/.gemrc /etc/gemrc \
    && chmod uog+r /etc/gemrc \
    && gem install -N passenger \
    && passenger-install-nginx-module \
    # cleanup and settings
    && bundle config --global build.nokogiri  "--use-system-libraries" \
    && bundle config --global build.nokogumbo "--use-system-libraries" \
    && find / -type f -iname \*.apk-new -delete \
    && rm -rf /var/cache/apk/* \
    && rm -rf /usr/lib/lib/ruby/gems/*/cache/* \
    && rm -rf ~/.gem \
    && rm -rf /var/cache/apk/*

# custom nginx.conf
COPY nginx.conf /opt/nginx/conf/
RUN mkdir /opt/nginx/sites-enabled && mkdir /opt/nginx/sites-available
COPY default /opt/nginx/sites-available/
RUN ln -s /opt/nginx/sites-available/default /opt/nginx/sites-enabled/default

ENV PATH=/opt/nginx/sbin:$PATH

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /opt/nginx/logs/access.log
RUN ln -sf /dev/stderr /opt/nginx/logs/error.log

EXPOSE 80 443
STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
