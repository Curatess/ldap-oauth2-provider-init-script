# base image
FROM debian:jessie
MAINTAINER luke.schleicher@curatess.com

# Update packages
RUN apt-get update

# Install tools
RUN apt-get install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev libsqlite3-dev redis-server cron wget git git-core ruby

# Install Ruby
RUN wget https://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.0.tar.gz
RUN tar -zxvf ruby-2.4.0.tar.gz
WORKDIR ruby-2.4.0
RUN autoconf
RUN ./configure
RUN make
RUN make install

# Reset working dir to root
WORKDIR /

# Install gems
RUN gem install bundler
RUN gem install foreman

# Prepare SSL Cert Folder
ARG SSLDOMAIN
RUN mkdir -p /etc/letsencrypt/$SSLDOMAIN

# Clone app github repo
WORKDIR /var/www
RUN git clone https://github.com/Curatess/ldap-oauth2-provider.git
WORKDIR ldap-oauth2-provider
RUN touch log/sidekiq.log

# Configure Rails
RUN sed -i.bu "s/placeholderdomain/$SSLDOMAIN/g" config/puma.rb
RUN rm -f tmp/pids/server.pid
RUN bundle install

# Set up cron job
RUN whenever --update-crontab
RUN systemctl enable cron.service
