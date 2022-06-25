#!/bin/sh

touch /app/log

# docker-compose でlog_dataを/tmpにマウントしている
# 調査したいアプリのログをlog_dataに出力するとログの差分も確認できる
if [ -e /tmp/development.log ]; then
  tail -f -n 0 /tmp/development.log >> /app/log &
fi
