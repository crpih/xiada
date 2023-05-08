FROM ruby:2.7.1-slim-buster

RUN chmod 1777 /tmp && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libgdbm-dev libsqlite3-dev git-core ssh-client

RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts

RUN gem install bundler

WORKDIR /myapp

COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock
RUN --mount=type=ssh bundle install

ARG XIADA_PROFILE
ARG XIADA_DATABASE=$XIADA_PROFILE

ENV XIADA_PROFILE=$XIADA_PROFILE
ENV XIADA_DATABASE=$XIADA_DATABASE
ENV XIADA_OPTIONS=''

COPY . /myapp
EXPOSE 4000
CMD ruby running/bin/server.rb -o 0.0.0.0 -p 4000 2>&1
