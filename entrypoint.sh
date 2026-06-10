#!/bin/bash

cd /home/container

echo "Iniciando Hercules..."

./login-server &
sleep 3

./char-server &
sleep 3

exec ./map-server
