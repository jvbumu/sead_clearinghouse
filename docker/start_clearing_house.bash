#!/bin/bash

APP_NAME=clearinghouse_app
APP_PORT=8060
APP_BUILD=NO
DOCKER_FILE=docker/Dockerfile
APP_RESTART=NO

for i in "$@"
do
    case $i in
        -n=*|--name=*)
            APP_NAME="${i#*=}"
            shift
        ;;
        -p=*|--port=*)
            APP_PORT="${i#*=}"
            shift
        ;;
        -f=*|--file=*)
            DOCKER_FILE="${i#*=}"
            shift
        ;;
        --build)
            APP_BUILD=YES
            shift
        ;;
        --restart)
            APP_RESTART=YES
            shift
        ;;
        *)
        ;;
    esac
done

function stop_containers {
  echo "Stopping running containers..."
  RUNNING_IDS=(`docker ps | grep ${APP_NAME} | awk '{print $1}'` )
  for id in ${RUNNING_IDS[@]}; do
    docker stop $id
  done
}

function remove_image {
  if [[ "$(docker images -q ${APP_NAME}:latest 2> /dev/null)" != "" ]]; then
     echo "Removing previous image..."
     docker rmi -f ${APP_NAME}:latest
  fi
}

function build_image {
  docker build -t $APP_NAME -f ${DOCKER_FILE} .
}

function run_image {
  docker run -d --rm --net=host -v /tmp -p ${APP_PORT}:${APP_PORT} $APP_NAME
}

if [ "$APP_BUILD" == "YES" ]; then

  stop_containers
  remove_image
  build_image

fi

if [ "$APP_RESTART" == "YES" ]; then

  stop_containers

fi

run_image
