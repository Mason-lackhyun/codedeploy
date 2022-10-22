#!/bin/bash

#Define Directory and Port
DEPLOY_DIRECTORY=/home/deploy
NGINX_DIRECTORY=/etc/nginx/conf.d

#Function Define
function Python_Config(){
  python3 -m venv venv
  source venv/bin/activate
  pip3 install --upgrade pip
  pip3 install -r requirement.txt
  nohup python app_$APP_PORT.py > ./nohup.out 2>&1 &
  sleep 5
}

function Health_Check() {
  if [[ $(curl -s 127.0.0.1/health_check | grep -o "OK") ]];
    then
  echo "Health_Check OK"
    else
  echo "Health_Check Fail"
  exit 1
  fi
}

function Nginx_Check(){
  sudo nginx -t
  if [[ $? == 0 ]]; then
    echo "Nginx Syntax Success"
  else
    echo "Nginx Syntax Error!!"
    exit 1
  fi
}


#Script Start
cd $DEPLOY_DIRECTORY

#첫 배포일 때,
if [[ -n $(cat $NGINX_DIRECTORY/*) ]]; then
  echo "This is not first Deploy"
else
  echo "This is first Deploy"
  
  #현재 포트 지정
  CURRENT_PORT=5000
  echo "CURRENT_PORT is $CURRENT_PORT"
  
  #폴더 생성 및 APP파일 복사
  mkdir lendit lendit2
  cp app_$CURRENT_PORT.py $DEPLOY_DIRECTORY/lendit
  xargs -n 1 cp -v requirement.txt <<<"$DEPLOY_DIRECTORY/lendit $DEPLOY_DIRECTORY/lendit2"
  cd $DEPLOY_DIRECTORY/lendit
  
  #Python 설정
  APP_PORT=$CURRENT_PORT
  Python_Config

  #Nginx복사
  cd $DEPLOY_DIRECTORY
  sudo cp cicd_$CURRENT_PORT.conf $NGINX_DIRECTORY/
  
  #Nginx Syntax_Check
  Nginx_Check
  sudo systemctl start nginx
  
  #Health_Check
  Health_Check
  exit 0
fi

#배포가 2번 이상부터~~~

#Nginx Port 확인
CURRENT_PORT=$(cat $NGINX_DIRECTORY/cicd_*.conf | grep -E -o "127.0.0.1:[0-9]{1,5}" | cut -d ":" -f2)
echo "CURRNET_PORT is $CURRENT_PORT"

#Target Port 확인
if [[ $CURRENT_PORT == "5000" ]]; then
  echo "5000 is not TARGET_PORT"
  DEPLOYMENT_DIRECTORY=$DEPLOY_DIRECTORY/lendit2
  TARGET_PORT=5001
else
  echo "5000 is TARGET_PORT"
  DEPLOYMENT_DIRECTORY=$DEPLOY_DIRECTORY/lendit
  TARGET_PORT=5000
fi

echo "TARGET_PORT IS $TARGET_PORT and DEPLOYMENT_DIRECTORY is $DEPLOYMENT_DIRECTORY"

#Python Port Kill and Status Check
echo "Python_$CURRENT_PORT is Running and kill now"
fuser -k $CURRENT_PORT/tcp

if [[ $(fuser $CURRENT_PORT/tcp) ]]; then
  echo "$CURRENT_PORT is alive, Error!"
  exit 1
else
  echo "$CURRENT_PORT is dead, Success!"
fi

#Copy APP
cp app_$TARGET_PORT.py $DEPLOYMENT_DIRECTORY

#Pyhton Build
APP_PORT=$TARGET_PORT
cd $DEPLOYMENT_DIRECTORY
if [[ -d venv ]]; then
  source venv/bin/activate
  nohup python app_$APP_PORT.py > ./nohup.out 2>&1 &
  sleep 5
else  
  Python_Config
fi

#Nginx File Copy
echo "Nginx file Copy"
sudo rm -f $NGINX_DIRECTORY/cicd_$CURRENT_PORT.conf
sudo cp $DEPLOY_DIRECTORY/cicd_$TARGET_PORT.conf $NGINX_DIRECTORY/

#Nginx Syntax_Check
Nginx_Check
sudo systemctl reload nginx

#Health_Check
Health_Check

echo "script finished"