#!/bin/bash
cd ~

#nginx 활성화
sudo systemctl enable nginx
sudo systemctl start nginx

#2번째 배포 위한 nginx 문법체크
sudo nginx -t && sudo systemctl reload nginx

if [[ $? != 0 ]];
then
 echo "nginx syntax Error"
 exit
else
 echo "nginx syntax check success!"
fi

#python 확인
count=$(ps -ef | grep python | wc -l)
pid=$(sudo netstat -tnlp | grep python | awk {'print $7'} | cut -d "/" -f1)


if [[ $count > 1 ]];
then
 echo "python is running and kill now"
 kill $pid
else
 echo "python is not running"
fi

#venv
python3 -m venv venv
source venv/bin/activate

#install
pip install flask

#pip upgrade
pip install --upgrade pip

#run
nohup flask --app app run > nohup.out 2>&1 &

sleep 5
#curl test

curl -s 127.0.0.1/health_check > log.log

sleep 5

#health_check
health_check=$(cat log.log | grep OK)

if [[ -n $health_check ]];
then
  echo "Health_Check is Good"
else
  echo "Fail"
  exit
fi

echo "script finished"
