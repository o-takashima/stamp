FROM ruby:2.7-alpine

ENV APP /app
ENV LANG C.UTF-8
ENV TZ=Asia/Tokyo
ENV EDITOR=vim

ARG USER
ARG USER_ID

# ユーザーグループを作成
RUN addgroup -S -g $USER_ID $USER \
  && adduser -S -u $USER_ID $USER -G $USER \
  && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
  && echo "${USER}:${USER}" | chpasswd

# create directory.
# 関連ディレクトリの作成＆オーナーをvagrantユーザーに変更
# $BUNDLE_APP_CONFIG == /usr/local/bundle
RUN mkdir -p $APP $BUNDLE_APP_CONFIG \
 && chown $USER:$USER $APP \
 && chown $USER:$USER $BUNDLE_APP_CONFIG

# rails credentials:edit のためにvimも入れとく
RUN apk update \
 && apk --no-cache add \
    bash \
    build-base \
    curl \
    curl-dev \
    g++ \
    gcc \
    git \
    less \
    linux-headers \
    libxml2-dev \
    libxslt-dev \
    libc-dev \
    make \
    mariadb-dev \
    mysql-client \
    mysql-dev \
    openssl \
    openssh \
    ruby-dev \
    tzdata \
    vim \
    yaml-dev \
    zlib-dev

# ここまでsuper user
USER $USER

WORKDIR $APP

COPY Gemfile $APP

RUN bundle install

COPY . $APP

CMD "/bin/bash"
