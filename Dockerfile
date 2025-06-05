FROM ruby:3.4.2-slim

ARG TRAIN=true

RUN chmod 1777 /tmp && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential pkg-config libsqlite3-dev git-core ssh-client

RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts

RUN gem install bundler

WORKDIR /myapp

COPY lib/xiada/version.rb /myapp/lib/xiada/version.rb
COPY xiada.gemspec /myapp/xiada.gemspec
COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock
RUN --mount=type=ssh bundle install

COPY . /myapp

RUN if [ "$TRAIN" = "true" ]; then \
      echo "Training data not available. Training..."; \
      cd training/bin && \
      make spanish_eslora && \
      make galician_eslora && \
      make galician_xiada_escrita && \
      make galician_xiada_oral && \
      cd ../.. \
    else \
      echo "Training data available. Skipping training."; \
    fi

EXPOSE 4000
CMD puma -p 4000 2>&1
