#!/usr/bin/env bash

# 随机创建非占用端口
# 判断当前端口是否被占用，没被占用返回0，反之1
function Listening {
   TCPListeningnum=`netstat -an | grep ":$1 " | awk '$1 == "tcp" && $NF == "LISTEN" {print $0}' | wc -l`
   UDPListeningnum=`netstat -an | grep ":$1 " | awk '$1 == "udp" && $NF == "0.0.0.0:*" {print $0}' | wc -l`
   (( Listeningnum = TCPListeningnum + UDPListeningnum ))
   if [ $Listeningnum == 0 ]; then
       echo "0"
   else
       echo "1"
   fi
}

#指定区间随机数
function random_range {
   shuf -i $1-$2 -n1
}

#得到随机端口
function get_random_port {
   echo "port=$SB_PORT"
   templ=0
   while [ $SB_PORT == 0 ]; do
       temp1=`random_range $1 $2`
       if [ `Listening $temp1` == 0 ] ; then
              SB_PORT=$temp1
       fi
   done
   echo "port=$SB_PORT"
}


# 创建用户添加密码
createUserNamePassword(){

    # 判断用户名
    if [[ -z "$USER_NAME" ]]; then
      echo "Please set 'USER_NAME' for linux"
      exit 2
    else
      sudo useradd -m $USER_NAME
      sudo adduser $USER_NAME sudo
    fi

    # 判断设置用户密码环境变量
    if [[ -z "$USER_PW" ]]; then
      echo "Please set 'USER_PW' for linux"
      exit 3
    else
      echo "$USER_NAME:$USER_PW" | sudo chpasswd
      sudo sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
      echo "Update linux user password !"
      echo -e "$USER_PW\n$USER_PW" | sudo passwd "$USER_NAME"
    fi

    # 判断用户hostname
    if [[ -z "$HOST_NAME" ]]; then
      echo "Please set 'HOST_NAME' for linux"
      exit 4
    else
      sudo hostname $HOST_NAME
    fi
}

# 获取配置启动sing-box
makeconfigSB(){
    # 获取下载路径
    # https://github.com/SagerNet/sing-box/releases

    ARCH_RAW=$(uname -m)
    case "${ARCH_RAW}" in
        'x86_64')    ARCH='amd64';;
        'x86' | 'i686' | 'i386')     ARCH='386';;
        'aarch64' | 'arm64') ARCH='arm64';;
        'armv7l')   ARCH='armv7';;
        's390x')    ARCH='s390x';;
        *)          echo "Unsupported architecture: ${ARCH_RAW}"; exit 1;;
    esac

    VERSION=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | head -n 1)  ; echo $VERSION
    URI_DOWNLOAD="https://github.com/SagerNet/sing-box/releases/download/$VERSION/sing-box_${VERSION#v}_$(uname -s)_${ARCH}.deb" ; echo $URI_DOWNLOAD

    # 文件名
    FILE_NAME=$(basename $URI_DOWNLOAD) ; echo $FILE_NAME

    # 下载安装包
    wget --verbose --show-progress=on --progress=bar --hsts-file=/tmp/wget-hsts -c "${URI_DOWNLOAD}" -O $FILE_NAME

    # 安装
    sudo dpkg -i $FILE_NAME    

    # 清理文件
    rm -fv ${FILE_NAME}
}

# 获取配置启动Ngrok
getStartNgrok(){
    # 判断 Ngrok 环境变量
    if [[ -z "$NGROK_AUTH_TOKEN" ]]; then
      echo "Please set 'NGROK_AUTH_TOKEN'"
      exit 5
    else
      # Ngrok安装
      curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt install ngrok

      sudo mkdir -pv /home/${USER_NAME}/ngrok

      # 配置文件生成
      echo -e "tunnels:\n  sing-box:\n    addr: ${SB_PORT}\n    proto: tcp\n  ssh:\n    addr: 22\n    proto: tcp\n" | sudo tee -a /home/${USER_NAME}/ngrok/ngrok.yml
      sudo ngrok config upgrade --config /home/${USER_NAME}/ngrok/ngrok.yml
      echo -e "authtoken: ${NGROK_AUTH_TOKEN}\n" | sudo tee -a /home/${USER_NAME}/ngrok/ngrok.yml
      
      # 启动 ngrok
      nohup sudo ngrok start --all --config /home/${USER_NAME}/ngrok/ngrok.yml --log /home/${USER_NAME}/ngrok/ngrok.log > /dev/null 2>&1 & disown
      # 等待
      sleep 10
    fi


    HAS_ERRORS=$(grep "command failed" < /home/${USER_NAME}/ngrok/ngrok.log)

    if [[ -z "$HAS_ERRORS" ]]; then
      echo "=========================================="
      
      # 获取ssh 映射域名网址
      SSH_N_ADDR=$(grep -o -E "name=(.+)" < /home/${USER_NAME}/ngrok/ngrok.log | grep ssh | sed 's; ;\n;g;s;:;\n;g;s;//;;g' | tail -n 2 | head -n 1) ; echo $SSH_N_ADDR
      # 获取ssh 映射端口
      SSH_N_PORT=$(grep -o -E "name=(.+)" < /home/${USER_NAME}/ngrok/ngrok.log | grep ssh | sed 's; ;\n;g;s;:;\n;g' | tail -n 1) ; echo $SSH_N_PORT

      # 获取sing-box 映射域名网址
      SB_N_ADDR=$(grep -o -E "name=(.+)" < /home/${USER_NAME}/ngrok/ngrok.log | grep sing-box | sed 's; ;\n;g;s;:;\n;g;s;//;;g' | tail -n 2 | head -n 1) ; echo $SB_N_ADDR
      # 获取sing-box 映射端口
      SB_N_PORT=$(grep -o -E "name=(.+)" < /home/${USER_NAME}/ngrok/ngrok.log | grep sing-box | sed 's; ;\n;g;s;:;\n;g' | tail -n 1) ; echo $SB_N_PORT

      # 创建证书和密钥
      sudo mkdir -pv /home/$USER_NAME/hysteria
      sudo openssl ecparam -genkey -name prime256v1 -out /home/$USER_NAME/hysteria/private.key
      sudo openssl req -new -x509 -days 36500 -key /home/$USER_NAME/hysteria/private.key -out /home/$USER_NAME/hysteria/cert.pem -subj "/CN="${SB_N_ADDR}

# 生成sing-box配置文件
config_content="
{
    \"log\": {
        \"disabled\": false,
        \"level\": \"debug\",
        \"timestamp\": true
    },
    \"inbounds\": [
        {
            \"type\": \"${SB_PROTOCOL}\",
            \"tag\": \"${SB_PROTOCOL_TAG}\",
            \"listen\": \"::\",
            \"listen_port\": ${SB_PORT},
            \"udp_disable_domain_unmapping\": false,
            \"users\": [
                {
                    \"name\": \"${USER_NAME}\",
                    \"password\": \"${SB_UUID}\"
                }
            ],
            \"ignore_client_bandwidth\": true,
            \"tls\": {
                \"enabled\": true,
                \"server_name\": \"${SB_N_ADDR}\",
                \"alpn\": [
                    \"h3\"
                ],
                \"certificate_path\": \"/home/${USER_NAME}/hysteria/cert.pem\",
                \"key_path\": \"/home/${USER_NAME}/hysteria/private.key\"
            },
            \"masquerade\": \"https://www.bing.com\"
        }   
    ],
    \"outbounds\": [
        {
            \"type\": \"direct\",
            \"tag\": \"direct-out\"
        }          
    ]
}"
      # 写入配置文件
      echo "$config_content" | sudo tee /etc/sing-box/config.json

      # 启动 sing-box
      sudo systemctl daemon-reload && sudo systemctl enable --now sing-box && sudo systemctl restart sing-box

# 反向生成客户端配置
config_content="
{
  \"dns\": {
    \"servers\": [
      {
        \"tag\": \"google\",
        \"address\": \"tls://8.8.8.8\"
      },
      {
        \"tag\": \"local\",
        \"address\": \"223.5.5.5\",
        \"detour\": \"direct\"
      }
    ],
    \"rules\": [
      {
        \"outbound\": \"any\",
        \"server\": \"local\"
      },
      {
        \"clash_mode\": \"Direct\",
        \"server\": \"local\"
      },
      {
        \"clash_mode\": \"Global\",
        \"server\": \"google\"
      },
      {
        \"type\": \"logical\",
        \"mode\": \"and\",
        \"rules\": [
          {
            \"rule_set\": \"geosite-geolocation-!cn\",
            \"invert\": true
          },
          {
            \"rule_set\": \"geosite-cn\"
          }
        ],
        \"server\": \"local\"
      }
    ]
  },
  \"route\": {
    \"rules\": [
      {
        \"type\": \"logical\",
        \"mode\": \"or\",
        \"rules\": [
          {
            \"protocol\": \"dns\"
          },
          {
            \"port\": 53
          }
        ],
        \"outbound\": \"dns-out\"
      },
      {
        \"ip_is_private\": true,
        \"outbound\": \"direct\"
      },
      {
        \"clash_mode\": \"Direct\",
        \"outbound\": \"direct\"
      },
      {
        \"clash_mode\": \"Global\",
        \"outbound\": \"default\"
      },
      {
        \"type\": \"logical\",
        \"mode\": \"or\",
        \"rules\": [
          {
            \"port\": 853
          },
          {
            \"network\": \"udp\",
            \"port\": 443
          },
          {
            \"protocol\": \"stun\"
          }
        ],
        \"outbound\": \"block\"
      },
      {
        \"type\": \"logical\",
        \"mode\": \"and\",
        \"rules\": [
          {
            \"rule_set\": \"geosite-geolocation-!cn\",
            \"invert\": true
          },
          {
            \"rule_set\": [
              \"geoip-cn\",
              \"geosite-cn\"
            ]
          }
        ],
        \"outbound\": \"direct\"
      }
    ],
    \"rule_set\": [
      {
        \"type\": \"remote\",
        \"tag\": \"geoip-cn\",
        \"format\": \"binary\",
        \"url\": \"https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs\"
      },
      {
        \"type\": \"remote\",
        \"tag\": \"geosite-cn\",
        \"format\": \"binary\",
        \"url\": \"https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-cn.srs\"
      },
      {
        \"type\": \"remote\",
        \"tag\": \"geosite-geolocation-!cn\",
        \"format\": \"binary\",
        \"url\": \"https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-geolocation-!cn.srs\"
      }
    ]
  },
  \"outbounds\": [
    {
      \"type\": \"${SB_PROTOCOL}\",
      \"server\": \"${SB_N_ADDR}\",
      \"server_port\": ${SB_N_PORT},
      \"up_mbps\": 100,
      \"down_mbps\": 100,
      \"password\": \"${SB_UUID}\",
      \"tls\": {
        \"enabled\": true,
        \"server_name\": \"${SB_N_ADDR}\"
      }
    },
    {
      \"type\": \"direct\",
      \"tag\": \"direct\"
    },
    {
      \"type\": \"dns\",
      \"tag\": \"dns-out\"
    },
    {
      \"type\": \"default\",
      \"tag\": \"default\"
    },
    {
      \"type\": \"block\",
      \"tag\": \"block\"
    }
  ]
}"
      # 写入内容
      sudo touch ../result.txt ; sudo ls result.txt
      echo -e "$(grep -o -E "name=(.+)" < /home/${USER_NAME}/ngrok/ngrok.log | sed 's; ;\n;g' | grep -v addr)\n" | sudo tee result.txt
      echo -e "To connect: \nssh -o ServerAliveInterval=60 [USER_NAME]@${SSH_N_ADDR} -p ${SSH_PORT}\n" | sudo tee -a result.txt
      echo -e ${REPORT_DATE}"创建，"${F_DATE}"之前停止可能提前停止" | sudo tee -a result.txt
      echo "$config_content" | sudo tee client-config.json
      echo "=========================================="
    else
      echo "$HAS_ERRORS"
      exit 6
    fi
}

# 同步时间
date '+%Y-%m-%d %H:%M:%S'
sudo ln -sfv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
sudo cat << EOF | sudo tee  /etc/timezone
Asia/Shanghai
EOF
date '+%Y-%m-%d %H:%M:%S'

# 安装必备工具
sudo apt update ; sudo apt-get install -y aptitude eatmydata aria2 catimg git micro locales curl wget tar socat qrencode uuid net-tools

# 手动模式配置默认编辑器
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/micro 40

# Configuration for locales
sudo perl -pi -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen
sudo perl -pi -e 's/en_GB.UTF-8 UTF-8/# en_GB.UTF-8 UTF-8/g' /etc/locale.gen
sudo locale-gen zh_CN ; sudo locale-gen zh_CN.UTF-8

cat << EOF | sudo tee /etc/default/locale
LANGUAGE=zh_CN.UTF-8
LC_ALL=zh_CN.UTF-8
LANG=zh_CN.UTF-8
LC_CTYPE=zh_CN.UTF-8
EOF

cat << EOF | sudo tee -a /etc/environment
export LANGUAGE=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LANG=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
EOF

cat << EOF | sudo tee -a $HOME/.bashrc
export LANGUAGE=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LANG=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
EOF

cat << EOF >> $HOME/.profile
export LANGUAGE=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LANG=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
EOF

sudo update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 LANGUAGE=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8

locale ; locale -a ; cat /etc/default/locale

source /etc/environment $HOME/.bashrc $HOME/.profile

# sing-box必备环境
SB_PORT=0
SB_PROTOCOL=hysteria2
SB_PROTOCOL_TAG=hy2-in
SB_UUID=$(uuid)

# 起止时间环境
REPORT_DATE=$(TZ=':Asia/Shanghai' date +'%Y-%m-%d %T')
F_DATE=$(date -d '${REPORT_DATE}' --date='6 hour' +'%Y-%m-%d %T')

# 这里指定了1~65535区间，从中任取一个未占用端口号
get_random_port 1 65535
createUserNamePassword
makeconfigSB
getStartNgrok

rm -fv set-sing-box.sh
