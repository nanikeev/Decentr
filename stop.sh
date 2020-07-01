#!/usr/bin/env bash

docker-compose -f docker-compose.yml down -v

# fix permissions
[[ "$OSTYPE" != "darwin"* ]] && sudo chown -R $USER:$USER .
