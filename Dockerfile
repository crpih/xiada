FROM ruby:2.7.1-slim-buster

RUN chmod 1777 /tmp && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libgdbm-dev libsqlite3-dev

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
CMD ruby running/bin/xiada_tagger.rb \
    -x running/${XIADA_PROFILE}/xml_values.txt \
    -s 4000 training/databases/${XIADA_PROFILE}/training_${XIADA_DATABASE}.db \
    ${XIADA_OPTIONS}
