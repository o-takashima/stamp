#!/bin/sh

PORT=${1:-3333}

bundle exec ruby app.rb -o 0.0.0.0 -p $PORT
