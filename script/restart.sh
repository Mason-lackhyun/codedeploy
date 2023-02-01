#!/bin/bash

#Define Directory and Port
DEPLOY_DIRECTORY=/home/deploy
NGINX_DIRECTORY=/etc/nginx/conf.d
APP_FOLDER=lendit
APP_FOLDER2=lendit2
NGINX_FILE_PREFIX=cicd
PORT=5000
PORT2=5001

#Script Start
cd $DEPLOY_DIRECTORY

#첫 배포 확인 및  포트 정의
if [[ ! -n $(cat ${NGINX_DIRECTORY}/*) ]] && [[ ! -d ${DEPLOY_DIRECTORY}/${APP_FOLDER} ]] && [[ ! -d ${DEPLOY_DIRECTORY}/${APP_FOLDER2} ]]; then
  echo "This is First Deploy!"
  FIRST_DEPLOY=TRUE
  #첫 배포니까 폴더 2개 모두 생성해줌
  mkdir ${DEPLOY_DIRECTORY}/${APP_FOLDER} ${DEPLOY_DIRECTORY}/${APP_FOLDER2}
  #포트 정의(현재, 타겟)
  CURRENT_PORT=$PORT2
  TARGET_PORT=$PORT
  echo "CURRENT_PORT is $PORT, TARGET_PORT is $PORT2"
  CURRENT_FOLDER=$APP_FOLDER2
  TARGET_FOLDER=$APP_FOLDER
else
  echo "This is Not First Deploy!"
  #포트 정의(현재, 타겟)
  CURRENT_PORT=$(cat ${NGINX_DIRECTORY}/${NGINX_FILE_PREFIX}_*.conf | grep -E -o "127.0.0.1:[0-9]{1,5}" | cut -d ":" -f2)
  if [[ $CURRENT_PORT == $PORT ]]; then
    echo "CURRENT_PORT is $PORT, TARGET_PORT is $PORT2"
    TARGET_PORT=$PORT2
    CURRENT_FOLDER=$APP_FOLDER
    TARGET_FOLDER=$APP_FOLDER2
  else
    echo "CURRENT_PORT is $PORT2, TARGET_PORT is $PORT"
    TARGET_PORT=$PORT
    CURRENT_FOLDER=$APP_FOLDER2
    TARGET_FOLDER=$APP_FOLDER
  fi
fi

#APP 디렉토리 설정 및 폴더 유무 체크(만약에 누군가에 의해서 폴더가 지워졌을 시)
APP_DIRECTORY=${DEPLOY_DIRECTORY}/$TARGET_FOLDER
if [[ -d $APP_DIRECTORY ]]; then
  echo "APP_DIRECTORY is ${APP_DIRECTORY}"
else
  echo "APP_DIRECTORY is None, Need to Create!"
  mkdir ${APP_DIRECTORY}
fi

#배포 될 타겟 포트 KILL
echo "TARGET_PORT ${TARGET_PORT} kill"
fuser -k $TARGET_PORT/tcp

#현재 포트 KILL 됬는지 상태 체크
if [[ $(fuser $TARGET_PORT/tcp) ]]; then
  echo "$TARGET_PORT is alive, Error!"
  exit 1
else
  echo "$TARGET_PORT is dead, Success!"
fi

#앱파일 복사
echo "APP file Copy Start"
cp $DEPLOY_DIRECTORY/source/* $APP_DIRECTORY

#파이썬 환경 구축 및 실행
cd $APP_DIRECTORY
echo "Python Package install and App Starts"
if [[ ! -d venv ]]; then
  #가상환경 및 패키지 설치
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
  #파이썬 실행
  nohup flask --app app run --port=$TARGET_PORT > nohup.out 2>&1 &
  sleep 5
else
  #venv폴더 존재 할 때 파이썬 앱 실행
  source venv/bin/activate
  nohup flask --app app run --port=$TARGET_PORT > nohup.out 2>&1 &
  sleep 5
fi

#파이썬 타겟포트 활성화 상태 확인
echo "Python Target Port Check"
if [[ $(fuser $TARGET_PORT/tcp) ]]; then
  echo "Python_$TARGET_PORT is Running!"
else
  echo "Python_$TARGET_PORT is Not Running, Failed!"
  exit 1
fi

#Nginx File Copy
echo "Nginx file Copy"
sudo rm -f ${NGINX_DIRECTORY}/${NGINX_FILE_PREFIX}_${CURRENT_PORT}.conf
sudo cp ${DEPLOY_DIRECTORY}/${NGINX_FILE_PREFIX}_${TARGET_PORT}.conf $NGINX_DIRECTORY/

#Nginx Check
sudo nginx -t || exit 1
echo "Nginx Config OK"
if [[ $FIRST_DEPLOY == "TRUE" ]]; then
    echo "Nginx Enable & Start"
    sudo systemctl enable nginx && sudo systemctl start nginx
fi
sudo systemctl reload nginx
sleep 3

#Health_Check
HTTP_HEALTHCHECK() {
  curl -s 127.0.0.1:$1/health_check | grep -o "OK"
  return $?
}

#Health_Check
if [[ ! $(HTTP_HEALTHCHECK "${TARGET_PORT}") ]] || [[ ! $(HTTP_HEALTHCHECK 80) ]];then
  echo "Health_Check Fail"
  exit 1
fi
echo "Health_Check OK"

#Banner Config
SED(){
  sudo sed -i "s/$1/$2/g" /etc/motd
}

if [[ $(cat /etc/motd | grep -E "^Active") ]]; then
  SED "${CURRENT_PORT}" "${TARGET_PORT}" && SED "${CURRENT_FOLDER}" "${TARGET_FOLDER}"
else
  echo "Active_Port is $TARGET_PORT and APP_Directory is $TARGET_FOLDER" | sudo tee -a  /etc/motd
fi
echo "BANNER config Finished"

echo "Script Finished"