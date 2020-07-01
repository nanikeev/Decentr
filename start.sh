#!/usr/bin/env bash

docker-compose -f docker-compose.yml up -d

# fix permissions
[[ "$OSTYPE" != "darwin"* ]] && sudo chown -R $USER:$USER .
