FROM ruby:3.1-alpine

ENV APP /app
ENV LANG C.UTF-8
ENV TZ=Asia/Tokyo
ENV EDITOR=vim

ARG USER
ARG USER_ID
ARG GROUP
ARG GROUP_ID

# ユーザーグループを作成
RUN addgroup -S -g $GROUP_ID $GROUP \
  && adduser -S -u $USER_ID $USER -G $GROUP \
  && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
  && echo "${USER}:${GROUP}" | chpasswd

# create directory.
# 関連ディレクトリの作成＆オーナーをvagrantユーザーに変更
# $BUNDLE_APP_CONFIG == /usr/local/bundle
RUN mkdir -p $APP $BUNDLE_APP_CONFIG \
 && chown $USER:$GROUP $APP \
 && chown $USER:$GROUP $BUNDLE_APP_CONFIG

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

RUN chown $USER:$GROUP /tmp

# ここまでsuper user
USER $USER

WORKDIR $APP

COPY Gemfile* $APP/

RUN bundle install

COPY . $APP

CMD "/bin/bash"
