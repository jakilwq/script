#!/bin/sh
VERSION_AREA=$1
VERSION_TYPE=$2
PUBLIC_VERSION=$3
CLIENT_DES=$4
SERVER_DES=$5
XML_DES=$6
PROJECT_NAME=$7
VERSION_HW=$8
MAKE_RESOURCE=$9

source /data/shell/config/${PROJECT_NAME}.conf

#SSH_PROXY='s1.gametrees.com'
SSH_PROXY='127.0.0.1'
SSH_PORT=22
SSH_OPT="ssh -o 'ProxyCommand ssh -p${SSH_PORT} root@${SSH_PROXY} nc %h %p;ServerAliveInterval=30'"
[ "${PROJECT_NAME}"x = ""x ] && echo -e "\033[47;31m 项目名参数缺失！\033[0m" && exit 1
[ "${VERSION_HW}"x = ""x ] && echo -e "\033[47;31m 海外标识参数缺失！\033[0m" && exit 1
echo "PUBLIC=`echo $PUBLIC_VERSION |tr ',' ' '|sed s/\^/\(/g | sed s/\$/\)/g`" > /opt/list  && source /opt/list
queue=`cat /data/shell/config/$PROJECT_NAME.conf |head -n 1 |awk -F' '  '{print NF-1}'`

function CHECK ()
{
    if [ $? -ne 0 ]
    then
        echo -e "\033[47;31m ${PROJECT_NAME}-${VERSION_AREA}-${VERSION_TYPE}-$1-$2-$3 部署失败！\033[0m"
        exit 1
    else
        echo -e "\033[47;32m ${PROJECT_NAME}-${VERSION_AREA}-${VERSION_TYPE}-$1-$2-$3 部署成功 \033[0m"
    fi
}
#####前端版本增量生成及部署#####
function CLIENT_ACTION ()
{
    #######前端版本增量生成########
     CLIENT_DIR=/data/${PROJECT_NAME}/${VERSION_AREA}_${VERSION_TYPE}/client/
     if [ ! -d ${CLIENT_DIR} ];then
     mkdir -p ${CLIENT_DIR}
    fi
    /data/shell/${PROJECT_NAME}_client/version_control.sh ${VERSION_AREA} ${VERSION_TYPE} $1 Yes ${MAKE_RESOURCE}
    ######前端版本部署########

    if [ "${VERSION_HW}"x = "yes"x ];then
        [ ${PROJECT_NAME} == onepiece -o ${PROJECT_NAME} == dragonballmobile ] && rsync -azP -e "${SSH_OPT}" /data/${PROJECT_NAME}/${VERSION_AREA}_${VERSION_TYPE}/client/AllZip/$1 ${CLIENT_DES}::${PROJECT_NAME}-public/${VERSION_AREA}_${VERSION_TYPE}/ ||  rsync -azP -e "${SSH_OPT}" /data/${PROJECT_NAME}/${VERSION_AREA}_${VERSION_TYPE}/client/$1 ${CLIENT_DES}::${PROJECT_NAME}-public/${VERSION_AREA}_${VERSION_TYPE}/ 
        CHECK $1 ${CLIENT_DES}
        ssh -o "ProxyCommand ssh -p${SSH_PORT} root@${SSH_PROXY} nc %h %p;ServerAliveInterval=30" ${CLIENT_DES} "sh /data/shell/rsync_client ${PROJECT_NAME} ${VERSION_AREA} ${VERSION_TYPE} $1"
        CHECK $1 ${CLIENT_DES}
    else
         [ ${PROJECT_NAME} == onepiece -o ${PROJECT_NAME} == dragonballmobile  ] && rsync -az /data/${PROJECT_NAME}/${VERSION_AREA}_${VERSION_TYPE}/client/AllZip/$1 ${CLIENT_DES}::${PROJECT_NAME}-public/${VERSION_AREA}_${VERSION_TYPE}/ || rsync -az /data/${PROJECT_NAME}/${VERSION_AREA}_${VERSION_TYPE}/client/$1 ${CLIENT_DES}::${PROJECT_NAME}-public/${VERSION_AREA}_${VERSION_TYPE}/
        CHECK $1 ${CLIENT_DES}
        ssh ${CLIENT_DES} "sh /data/shell/rsync_client ${PROJECT_NAME} ${VERSION_AREA} ${VERSION_TYPE} $1"
        CHECK $1 ${CLIENT_DES}
    fi
}
#####后端版本本地存储及部署#####
function SERVER_ACTION ()
{
    GAMEAPP_DIR=/data/${PROJECT_NAME}/${VERSION_AREA}_${VERSION_TYPE}/server/$1/
    if [ ! -d ${GAMEAPP_DIR} ];then
    mkdir -p ${GAMEAPP_DIR}
    fi
    ############后端版本同步到本地存储###########
    rsync -azP ${MAKE_RESOURCE}:/data/gameapp/${PROJECT_NAME}/${VERSION_AREA}_${VERSION_TYPE}/server/$1/$2 ${GAMEAPP_DIR}

    #####后端版本部署#####
    if [ "${VERSION_HW}"x = "yes"x ];then
        rsync -azP -e "${SSH_OPT}" ${GAMEAPP_DIR}/$2 ${SERVER_DES}::${PROJECT_NAME}-serverpublic/$1
        CHECK $1 $2 ${SERVER_DES}
        ssh -o "ProxyCommand ssh -p${SSH_PORT} root@${SSH_PROXY} nc %h %p;ServerAliveInterval=30" ${SERVER_DES} "sh /data/shell/rsync_server ${PROJECT_NAME} ${VERSION_AREA} ${VERSION_TYPE} $1 $2"
        CHECK $1 $2 ${SERVER_DES}
    else
echo "this is ${SERVER_DES}::${PROJECT_NAME}-serverpublic $1"
        rsync -azP ${GAMEAPP_DIR}/$2 ${SERVER_DES}::${PROJECT_NAME}-serverpublic/$1/
        CHECK $1 $2 ${SERVER_DES}
        ssh ${SERVER_DES} "sh /data/shell/rsync_server ${PROJECT_NAME} ${VERSION_AREA} ${VERSION_TYPE} $1 $2"
        CHECK $1 $2 ${SERVER_DES}
    fi
}
#####后端配置版本本地存储及部署#####
function XML_ACTION ()
{
    XML_DIR=/data/${PROJECT_NAME}/${VERSION_AREA}_${VERSION_TYPE}/xml/
    if [ ! -d ${XML_DIR} ];then
       mkdir -p ${XML_DIR}
    fi
    #####后端配置版本同步到本地存储#####
    rsync -azP ${MAKE_RESOURCE}:/data/gameapp/${PROJECT_NAME}/${VERSION_AREA}_${VERSION_TYPE}/xml/$1 ${XML_DIR}
    CHECK $1 ${XML_DES}
    #####后端配置版本部署#####
    if [ "${VERSION_HW}"x = "yes"x ];then
        rsync -azP -e "${SSH_OPT}" ${XML_DIR}/$1 ${XML_DES}::${PROJECT_NAME}-xmlsource/${VERSION_AREA}
    CHECK $1 ${XML_DES}
    else
        rsync -azP ${XML_DIR}/$1 ${XML_DES}::${PROJECT_NAME}-xmlsource/${VERSION_AREA}
        CHECK $1 ${XML_DES}
    fi
}

for ((i=0;i<=${queue};i++));do
    if [ `echo ${APP_NAME[$i]}` == "no" ];then
        echo "no"
    elif [ `echo ${APP_NAME[$i]}`  == "client"  -o `echo ${APP_NAME[$i]}` == "xml" ];then
        `echo ${APP_ACTION[$i]}` `echo ${PUBLIC[$i]}` 
    else 
        `echo ${APP_ACTION[$i]}` `echo ${APP_NAME[$i]}`  `echo ${PUBLIC[$i]}`  
    fi 
done
