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

# 获取配置启动ngrok 和 sing-box
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

    VERSION=$(curl -sL "https://github.com/SagerNet/sing-box/releases" | grep -oP '(?<=\/SagerNet\/sing-box\/releases\/tag\/)[^"]+' | head -n 1) ; echo $VERSION
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

# ngrok配置文件生成
cat << EOL | sudo tee /home/${USER_NAME}/ngrok/ngrok.yml
authtoken: ${NGROK_AUTH_TOKEN}

tunnels:
  ssh:
    proto: tcp
    addr: 22

  vlessreality:
    proto: tcp
    addr: ${V_R_PORT}

  sing-box:
    proto: tcp
    addr: ${SB_PORT}
EOL
      # 应用 ngrok 配置
      sudo ngrok config upgrade --config /home/${USER_NAME}/ngrok/ngrok.yml
      # 启动 ngrok
      sudo nohup ngrok start --all --config /home/${USER_NAME}/ngrok/ngrok.yml --log /home/${USER_NAME}/ngrok/ngrok.log > /dev/null 2>&1 & disown
      # 等待
      sleep 10
    fi

    HAS_ERRORS=$(grep "command failed" < /home/${USER_NAME}/ngrok/ngrok.log)

    if [[ -z "$HAS_ERRORS" ]]; then
      echo "=========================================="
      # 获取 ngrok 映射信息
      NGROK_INFO=$(curl -s http://127.0.0.1:4040/api/tunnels)

      # 提取映射端口和域名
      SSH_N_INFO=$(echo "$NGROK_INFO" | jq -r '.tunnels[] | select(.name=="ssh") | .public_url')
      VLESSREALITY_N_INFO=$(echo "$NGROK_INFO" | jq -r '.tunnels[] | select(.name=="vlessreality") | .public_url')
      SINGBOX_N_INFO=$(echo "$NGROK_INFO" | jq -r '.tunnels[] | select(.name=="sing-box") | .public_url')

      # 使用正则表达式提取域名和端口
      SSH_N_DOMAIN=$(echo "$SSH_N_INFO" | awk -F[/:] '{print $4}')
      SSH_N_PORT=$(echo "$SSH_N_INFO" | awk -F[/:] '{print $5}')

      VLESSREALITY_N_DOMAIN=$(echo "$VLESSREALITY_N_INFO" | awk -F[/:] '{print $4}')
      VLESSREALITY_N_PORT=$(echo "$VLESSREALITY_N_INFO" | awk -F[/:] '{print $5}')

      SINGBOX_N_DOMAIN=$(echo "$SINGBOX_N_INFO" | awk -F[/:] '{print $4}')
      SINGBOX_N_PORT=$(echo "$SINGBOX_N_INFO" | awk -F[/:] '{print $5}')

      # 创建证书和密钥
      sudo mkdir -pv /home/$USER_NAME/hysteria
      sudo openssl ecparam -genkey -name prime256v1 -out /home/$USER_NAME/hysteria/private.key
      sudo openssl req -new -x509 -days 36500 -key /home/$USER_NAME/hysteria/private.key -out /home/$USER_NAME/hysteria/cert.pem -subj "/CN=bing.com"

      # 生成 reality 私钥公钥对
      R_PRIVATEKEY_PUBLICKEY="$(sing-box generate reality-keypair)"
      # 提取私钥
      R_PRIVATEKEY="$(echo $R_PRIVATEKEY_PUBLICKEY | awk '{print $2}')"
      # 提取公钥
      R_PUBLICKEY="$(echo $R_PRIVATEKEY_PUBLICKEY | awk '{print $4}')"

# 生成sing-box配置文件 写入配置文件
cat << EOL | sudo tee /etc/sing-box/config.json > /dev/null
{
	"inbounds": [{
		"type": "${SB_PROTOCOL}",
		"listen": "::",
		"listen_port": ${SB_PORT},
		"users": [{
			"password": "${SB_UUID}"
		}],
		"tls": {
			"enabled": true,
			"alpn": ["h3"],
			"certificate_path": "/home/${USER_NAME}/cert.pem",
			"key_path": "/home/${USER_NAME}/private.key"
		}
	}, {
		"type": "${V_PROTOCOL}",
		"listen": "::",
		"listen_port": ${V_R_PORT},
		"users": [{
			"uuid": "${V_UUID}",
			"flow": "xtls-rprx-vision"
		}],
		"tls": {
			"enabled": true,
			"server_name": "${R_STEAL_WEBSITE_CERTIFICATES}",
			"reality": {
				"enabled": true,
				"handshake": {
					"server": "${R_STEAL_WEBSITE_CERTIFICATES}",
					"server_port": ${V_R_PORT}
				},
				"private_key": "${R_PRIVATEKEY}",
				"short_id": ["${R_HEX}"]
			}
		}
	}],
	"outbounds": [{
		"type": "direct"
	}]
}
EOL

      # 启动 sing-box
      sudo systemctl daemon-reload && sudo systemctl enable --now sing-box && sudo systemctl restart sing-box

# 反向生成客户端配置 写入内容
cat << EOL | sudo tee client-config.json > /dev/null
{
	"dns": {
		"rules": [{
			"clash_mode": "global",
			"server": "remote"
		}, {
			"clash_mode": "direct",
			"server": "local"
		}, {
			"outbound": ["any"],
			"server": "local"
		}, {
			"geosite": "cn",
			"server": "local"
		}],
		"servers": [{
			"address": "https://1.1.1.1/dns-query",
			"detour": "select",
			"tag": "remote"
		}, {
			"address": "https://223.5.5.5/dns-query",
			"detour": "direct",
			"tag": "local"
		}],
		"strategy": "ipv4_only"
	},
	"experimental": {
		"clash_api": {
			"external_controller": "0.0.0.0:9090",
			"secret": "",
			"store_selected": true
		}
	},
	"inbounds": [{
		"auto_route": true,
		"domain_strategy": "ipv4_only",
		"endpoint_independent_nat": true,
		"inet4_address": "172.19.0.1/30",
		"mtu": 9000,
		"sniff": true,
		"sniff_override_destination": true,
		"strict_route": true,
		"type": "tun"
	}, {
		"domain_strategy": "ipv4_only",
		"listen": "0.0.0.0",
		"listen_port": 2333,
		"sniff": true,
		"sniff_override_destination": true,
		"tag": "socks-in",
		"type": "socks",
		"users": []
	}, {
		"domain_strategy": "ipv4_only",
		"listen": "0.0.0.0",
		"listen_port": 2334,
		"sniff": true,
		"sniff_override_destination": true,
		"tag": "mixed-in",
		"type": "mixed",
		"users": []
	}],
	"log": {
		"disabled": false,
		"level": "debug",
		"timestamp": true
	},
	"outbounds": [{
		"tag": "select",
		"type": "selector",
		"default": "urltest",
		"outbounds": ["urltest", "${SB_R_PROTOCOL_OUT_TAG}", "${SB_H_PROTOCOL_OUT_TAG}"]
	}, {
		"type": "${V_PROTOCOL}",
		"tag": "${SB_R_PROTOCOL_OUT_TAG}",
		"uuid": "${V_UUID}",
		"flow": "xtls-rprx-vision",
		"packet_encoding": "xudp",
		"server": "${VLESSREALITY_N_DOMAIN}",
		"server_port": ${VLESSREALITY_N_PORT},
		"tls": {
			"enabled": true,
			"server_name": "${VLESSREALITY_N_DOMAIN}",
			"utls": {
				"enabled": true,
				"fingerprint": "chrome"
			},
			"reality": {
				"enabled": true,
				"public_key": "${R_PUBLICKEY}",
				"short_id": "${R_HEX}"
			}
		}
	}, {
		"type": "${SB_PROTOCOL}",
		"server": "${SINGBOX_N_DOMAIN}",
		"server_port": ${SINGBOX_N_PORT},
		"tag": "${SB_H_PROTOCOL_OUT_TAG}",
		"up_mbps": 30,
		"down_mbps": 150,
		"password": "${SB_UUID}",
		"tls": {
			"enabled": true,
			"server_name": "bing.com",
			"insecure": true,
			"alpn": ["h3"]
		}
	}, {
		"tag": "direct",
		"type": "direct"
	}, {
		"tag": "block",
		"type": "block"
	}, {
		"tag": "dns-out",
		"type": "dns"
	}, {
		"tag": "urltest",
		"type": "urltest",
		"outbounds": ["${SB_R_PROTOCOL_OUT_TAG}", "${SB_H_PROTOCOL_OUT_TAG}"]
	}],
	"route": {
		"auto_detect_interface": true,
		"rules": [{
			"geosite": "category-ads-all",
			"outbound": "block"
		}, {
			"outbound": "dns-out",
			"protocol": "dns"
		}, {
			"clash_mode": "direct",
			"outbound": "direct"
		}, {
			"clash_mode": "global",
			"outbound": "select"
		}, {
			"geoip": ["cn", "private"],
			"outbound": "direct"
		}, {
			"geosite": "geolocation-!cn",
			"outbound": "select"
		}, {
			"geosite": "cn",
			"outbound": "direct"
		}],
		"geoip": {
			"download_detour": "select"
		},
		"geosite": {
			"download_detour": "select"
		}
	}
}
EOL

cat << EOL | sudo tee result.txt > /dev/null
SSH is accessible at: ${SSH_N_DOMAIN}:${SSH_N_PORT}
VLESSReality is accessible at: ${VLESSREALITY_N_DOMAIN}:${VLESSREALITY_N_PORT}
Sing-Box is accessible at: ${SINGBOX_N_DOMAIN}:${SINGBOX_N_PORT}
Time Frame is accessible at: ${REPORT_DATE}~${F_DATE}
EOL

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
sudo apt update ; sudo apt-get install -y aria2 catimg git locales curl wget tar socat qrencode uuid net-tools jq

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
SB_PROTOCOL=hysteria2
SB_PORT=0
SB_UUID=$(uuid)
V_PROTOCOL=vless
V_R_PORT=443
V_UUID=$(uuid)
R_STEAL_WEBSITE_CERTIFICATES=www.pornhub.com
# 生成16位16进制区分主机
R_HEX=$(openssl rand -hex 8)
SB_R_PROTOCOL_OUT_TAG=sing-box-reality
SB_H_PROTOCOL_OUT_TAG=sing-box-hysteria2


# 起止时间环境
REPORT_DATE=$(TZ=':Asia/Shanghai' date +'%Y-%m-%d %T')
F_DATE=$(date -d '${REPORT_DATE}' --date='6 hour' +'%Y-%m-%d %T')

# 这里指定了1~65535区间，从中任取一个未占用端口号
get_random_port 1 65535
createUserNamePassword
makeconfigSB
getStartNgrok

rm -fv set-sing-box.sh
