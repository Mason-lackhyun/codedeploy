#!/bin/bash

if [[ $(cat ~/.bash_profile | grep active) ]]; then
  sed -i "s/$1/$2/g" ~/.bash_profile
  source ~/.bash_profile
else
  echo "export port='Active is $2'" >> ~/.bash_profile
  source ~/.bash_profile
fi
