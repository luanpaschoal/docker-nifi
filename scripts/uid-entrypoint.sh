#!/bin/bash

if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-nifi}:x:$(id -u):0:${USER_NAME:-nifi} user:${HOME}:/sbin/nologin" >> /etc/passwd
  fi
fi

exec "$@" 
