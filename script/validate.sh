#!/bin/bash

#proxy validate
po=$(cat log.log | grep He)
he=$(cat log.log | grep O)

if [[ -n $po ]];
then
  echo "proxy is validate"
else
  exit
fi

#health_Check validate
if [[ -n $he ]];
then
  echo "health_check is validate"
else
  exit
fi

echo "validate finished"
