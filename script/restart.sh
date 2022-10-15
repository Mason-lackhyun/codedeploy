#!/bin/bash
cd ~

#nginx 활성화
sudo systemctl enable nginx
sudo systemctl start nginx

#venv
python3 -m venv venv 

source venv/bin/activate

#install
pip install flask

#run
nohup flask --app app run > nohup.out 2>&1 &

#deactivate
deactivate

cd ~

sleep 10

#curl test

curl -s 127.0.0.1 | grep -o "Hello, World" >> log.log
curl -s 127.0.0.1/health_check >> log.log

cd ~
sleep 5

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

echo "script finished"
