#!/usr/bin/env bash
# 前戏初始化
initall() {
	date '+%Y-%m-%d %H:%M:%S'
	sudo ln -sfv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	sudo cat <<SMALLFLOWERCAT1995 | sudo tee /etc/timezone
Asia/Shanghai
SMALLFLOWERCAT1995
	date '+%Y-%m-%d %H:%M:%S'
	sudo apt update
	sudo apt-get install -y aria2 catimg git locales curl wget tar socat qrencode uuid net-tools jq
	sudo perl -pi -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen
	sudo perl -pi -e 's/en_GB.UTF-8 UTF-8/# en_GB.UTF-8 UTF-8/g' /etc/locale.gen
	sudo locale-gen zh_CN
	sudo locale-gen zh_CN.UTF-8
	cat <<SMALLFLOWERCAT1995 | sudo tee /etc/default/locale
LANGUAGE=zh_CN.UTF-8
LC_ALL=zh_CN.UTF-8
LANG=zh_CN.UTF-8
LC_CTYPE=zh_CN.UTF-8
SMALLFLOWERCAT1995
	cat <<SMALLFLOWERCAT1995 | sudo tee -a /etc/environment
export LANGUAGE=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LANG=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
SMALLFLOWERCAT1995
	cat <<SMALLFLOWERCAT1995 | sudo tee -a $HOME/.bashrc
export LANGUAGE=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LANG=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
SMALLFLOWERCAT1995
	cat <<SMALLFLOWERCAT1995 >>$HOME/.profile
export LANGUAGE=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LANG=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
SMALLFLOWERCAT1995
	sudo update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 LANGUAGE=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8
	locale
	locale -a
	cat /etc/default/locale
	source /etc/environment $HOME/.bashrc $HOME/.profile
}
# 生成随机不占用的端口
get_random_port() {
	min=$1
	max=$2
	port=$(sudo shuf -i $min-$max -n1)
	tcp=$(sudo netstat -an | grep ":$port " | awk '$1 == "tcp" && $NF == "LISTEN" {print $0}' | wc -l)
	udp=$(sudo netstat -an | grep ":$port " | awk '$1 == "udp" && $NF == "0.0.0.0:*" {print $0}' | wc -l)
	while [ $((tcp + udp)) -gt 0 ]; do
		port=$(sudo shuf -i $min-$max -n1)
		tcp=$(sudo netstat -an | grep ":$port " | awk '$1 == "tcp" && $NF == "LISTEN" {print $0}' | wc -l)
		udp=$(sudo netstat -an | grep ":$port " | awk '$1 == "udp" && $NF == "0.0.0.0:*" {print $0}' | wc -l)
	done
	echo $port
}
# 初始化用户密码
createUserNamePassword() {
	if [[ -z "$USER_NAME" ]]; then
		echo "Please set 'USER_NAME' for linux"
		exit 2
	else
		sudo useradd -m $USER_NAME
		sudo adduser $USER_NAME sudo
	fi
	if [[ -z "$USER_PW" ]]; then
		echo "Please set 'USER_PW' for linux"
		exit 3
	else
		echo "$USER_NAME:$USER_PW" | sudo chpasswd
		sudo sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
		echo "Update linux user password !"
		echo -e "$USER_PW\n$USER_PW" | sudo passwd "$USER_NAME"
	fi
	if [[ -z "$HOST_NAME" ]]; then
		echo "Please set 'HOST_NAME' for linux"
		exit 4
	else
		sudo hostname $HOST_NAME
	fi
}
# 下载 sing-box cloudflared ngrok
getStartSing-box_cloudflared_ngrok() {
	ARCH_RAW=$(uname -m)
	case "$ARCH_RAW" in
	'x86_64') ARCH='amd64' ;;
	'x86' | 'i686' | 'i386') ARCH='386' ;;
	'aarch64' | 'arm64') ARCH='arm64' ;;
	'armv7l') ARCH='armv7' ;;
	's390x') ARCH='s390x' ;;
	*)
		echo "Unsupported architecture: $ARCH_RAW"
		exit 1
		;;
	esac
	VERSION=$(curl -sL "https://github.com/SagerNet/sing-box/releases" | grep -oP '(?<=\/SagerNet\/sing-box\/releases\/tag\/)[^"]+' | head -n 1)
	echo $VERSION
	URI_DOWNLOAD="https://github.com/SagerNet/sing-box/releases/download/$VERSION/sing-box_${VERSION#v}_$(uname -s)_$ARCH.deb"
	echo $URI_DOWNLOAD
	FILE_NAME=$(basename $URI_DOWNLOAD)
	echo $FILE_NAME
	wget --verbose --show-progress=on --progress=bar --hsts-file=/tmp/wget-hsts -c "$URI_DOWNLOAD" -O $FILE_NAME
	sudo dpkg -i $FILE_NAME
	rm -fv $FILE_NAME
 
	VERSION=$(curl -sL "https://github.com/cloudflare/cloudflared/releases" | grep -oP '(?<=\/cloudflare\/cloudflared\/releases\/tag\/)[^"]+' | head -n 1)
	echo $VERSION
	URI_DOWNLOAD="https://github.com/cloudflare/cloudflared/releases/download/$VERSION/cloudflared-$(uname -s)-$ARCH.deb"
	echo $URI_DOWNLOAD
	FILE_NAME=$(basename $URI_DOWNLOAD)
	echo $FILE_NAME
	wget --verbose --show-progress=on --progress=bar --hsts-file=/tmp/wget-hsts -c "$URI_DOWNLOAD" -O $FILE_NAME
	sudo dpkg -i $FILE_NAME
	rm -fv $FILE_NAME
 
	sudo mkdir -pv /home/$USER_NAME/cloudflared
	
	if [[ -z "$NGROK_AUTH_TOKEN" ]]; then
		echo "Please set 'NGROK_AUTH_TOKEN'"
		exit 5
	else
		curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt install ngrok
	        sudo mkdir -pv /home/$USER_NAME/ngrok
        fi
	cat <<SMALLFLOWERCAT1995 | sudo tee /home/$USER_NAME/ngrok/ngrok.yml >/dev/null
authtoken: $NGROK_AUTH_TOKEN

tunnels:
  ssh:
    proto: tcp
    addr: 22

  vless:
    proto: tcp
    addr: $V_PORT

  vmess:
    proto: tcp
    addr: $VM_PORT
SMALLFLOWERCAT1995
	sudo ngrok config upgrade --config /home/$USER_NAME/ngrok/ngrok.yml
        sudo nohup ngrok start --all --config /home/${USER_NAME}/ngrok/ngrok.yml --log /home/${USER_NAME}/ngrok/ngrok.log > /dev/null 2>&1 & disown
	sleep 10
        HAS_ERRORS=$(grep "command failed" < /home/${USER_NAME}/ngrok/ngrok.log)
	if [[ -z "$HAS_ERRORS" ]]; then
		echo "=========================================="
		NGROK_INFO=$(curl -s http://127.0.0.1:4040/api/tunnels)
		SSH_N_INFO=$(echo "$NGROK_INFO" | jq -r '.tunnels[] | select(.name=="ssh") | .public_url')
		VLESS_N_INFO=$(echo "$NGROK_INFO" | jq -r '.tunnels[] | select(.name=="vless") | .public_url')
		VMESS_N_INFO=$(echo "$NGROK_INFO" | jq -r '.tunnels[] | select(.name=="vmess") | .public_url')
		SSH_N_DOMAIN=$(echo "$SSH_N_INFO" | awk -F[/:] '{print $4}')
		SSH_N_PORT=$(echo "$SSH_N_INFO" | awk -F[/:] '{print $5}')
		VLESS_N_DOMAIN=$(echo "$VLESS_N_INFO" | awk -F[/:] '{print $4}')
		VLESS_N_PORT=$(echo "$VLESS_N_INFO" | awk -F[/:] '{print $5}')
		VMESS_N_DOMAIN=$(echo "$VMESS_N_INFO" | awk -F[/:] '{print $4}')
		VMESS_N_PORT=$(echo "$VMESS_N_INFO" | awk -F[/:] '{print $5}')
		R_PRIVATEKEY_PUBLICKEY="$(sing-box generate reality-keypair)"
		R_PRIVATEKEY="$(echo $R_PRIVATEKEY_PUBLICKEY | awk '{print $2}')"
		R_PUBLICKEY="$(echo $R_PRIVATEKEY_PUBLICKEY | awk '{print $4}')"
		V_UUID="$(sing-box generate uuid)"
		VM_UUID="$(sing-box generate uuid)"
		R_HEX="$(sing-box generate rand --hex 8)"
		VM_HEX="$(sing-box generate rand --hex 8)"
		WS_PATH="$(sing-box generate rand --hex 6)"
		cat <<SMALLFLOWERCAT1995 | sudo tee /etc/sing-box/config.json >/dev/null
{
  "log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "sniff": true,
      "sniff_override_destination": true,
      "type": "$V_PROTOCOL",
      "tag": "$V_PROTOCOL_IN_TAG",
      "listen": "::",
      "listen_port": $V_PORT,
      "users": [
        {
          "uuid": "$V_UUID",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "$R_STEAL_WEBSITE_CERTIFICATES",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "$R_STEAL_WEBSITE_CERTIFICATES",
            "server_port": $R_STEAL_WEBSITE_PORT
          },
          "private_key": "$R_PRIVATEKEY",
          "short_id": [
            "$R_HEX"
          ]
        }
      }
    },
    {
      "sniff": true,
      "sniff_override_destination": true,
      "type": "$VM_PROTOCOL",
      "tag": "$VM_PROTOCOL_IN_TAG",
      "listen": "::",
      "listen_port": $VM_PORT,
      "users": [
        {
          "uuid": "$VM_UUID",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "$VM_TYPE",
        "path": "$VM_HEX",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ]
}
SMALLFLOWERCAT1995
		sudo systemctl daemon-reload && sudo systemctl enable --now sing-box && sudo systemctl restart sing-box
		sudo nohup cloudflared tunnel --url http://localhost:$VM_PORT --no-autoupdate --edge-ip-version auto --protocol http2 > /home/$USER_NAME/cloudflared/cloudflared.log 2>&1 & disown
                sleep 5
		CLOUDFLARED_DOMAIN="$(cat /home/$USER_NAME/cloudflared/cloudflared.log | grep trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')"
		if [ "$CLOUDFLARED_DOMAIN" != "" ]; then
			echo $CLOUDFLARED_DOMAIN
		else
			CLOUDFLARED_DOMAIN=$VMESS_N_DOMAIN
		fi
		cat <<SMALLFLOWERCAT1995 | sudo tee client-config.json >/dev/null
{
  "log": {
    "level": "debug",
    "timestamp": true
  },
  "experimental": {
    "clash_api": {
      "external_controller": "0.0.0.0:9090",
      "external_ui_download_url": "https://mirror.ghproxy.com/https://github.com/MetaCubeX/Yacd-meta/archive/gh-pages.zip",
      "external_ui_download_detour": "direct",
      "external_ui": "ui",
      "secret": "",
      "default_mode": "rule"
    },
    "cache_file": {
      "enabled": true,
      "store_fakeip": false
    }
  },
  "dns": {
    "servers": [
      {
        "tag": "proxyDns",
        "address": "https://8.8.8.8/dns-query",
        "detour": "$SB_ALL_PROTOCOL_OUT_TAG"
      },
      {
        "tag": "localDns",
        "address": "https://223.5.5.5/dns-query",
        "detour": "direct"
      },
      {
        "tag": "block",
        "address": "rcode://success"
      },
      {
        "tag": "remote",
        "address": "fakeip"
      }
    ],
    "rules": [
      {
        "domain": [
          "ghproxy.com",
          "cdn.jsdelivr.net",
          "testingcf.jsdelivr.net"
        ],
        "server": "localDns"
      },
      {
        "rule_set": "geosite-category-ads-all",
        "server": "block"
      },
      {
        "outbound": "any",
        "server": "localDns",
        "disable_cache": true
      },
      {
        "rule_set": "geosite-cn",
        "server": "localDns"
      },
      {
        "clash_mode": "direct",
        "server": "localDns"
      },
      {
        "clash_mode": "global",
        "server": "proxyDns"
      },
      {
        "rule_set": "geosite-geolocation-!cn",
        "server": "proxyDns"
      },
      {
        "query_type": [
          "A",
          "AAAA"
        ],
        "server": "remote"
      }
    ],
    "fakeip": {
      "enabled": true,
      "inet4_range": "198.18.0.0/15",
      "inet6_range": "fc00::/18"
    },
    "independent_cache": true,
    "strategy": "ipv4_only"
  },
  "route": {
    "auto_detect_interface": true,
    "final": "$SB_ALL_PROTOCOL_OUT_TAG",
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
      {
        "network": "udp",
        "port": 443,
        "outbound": "block"
      },
      {
        "rule_set": "geosite-category-ads-all",
        "outbound": "block"
      },
      {
        "clash_mode": "direct",
        "outbound": "direct"
      },
      {
        "clash_mode": "global",
        "outbound": "$SB_ALL_PROTOCOL_OUT_TAG"
      },
      {
        "domain": [
          "clash.razord.top",
          "yacd.metacubex.one",
          "yacd.haishan.me",
          "d.metacubex.one"
        ],
        "outbound": "direct"
      },
      {
        "rule_set": "geosite-wechat",
        "outbound": "WeChat"
      },
      {
        "rule_set": "geosite-geolocation-!cn",
        "outbound": "$SB_ALL_PROTOCOL_OUT_TAG"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      },
      {
        "rule_set": "geoip-cn",
        "outbound": "direct"
      },
      {
        "rule_set": "geosite-cn",
        "outbound": "direct"
      },
      {
        "rule_set": "geosite-apple",
        "outbound": "Apple"
      },
      {
        "rule_set": "geosite-microsoft",
        "outbound": "Microsoft"
      }
    ],
    "rule_set": [
      {
        "tag": "geoip-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/cn.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/cn.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-geolocation-!cn",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/geolocation-!cn.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-category-ads-all",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/category-ads-all.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-wechat",
        "type": "remote",
        "format": "source",
        "url": "https://testingcf.jsdelivr.net/gh/Toperlock/sing-box-geosite@main/wechat.json",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-apple",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/apple.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-microsoft",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/microsoft.srs",
        "download_detour": "direct"
      }
    ]
  },
  "inbounds": [
    {
      "type": "tun",
      "inet4_address": "172.19.0.1/30",
      "mtu": 9000,
      "auto_route": true,
      "strict_route": true,
      "sniff": true,
      "endpoint_independent_nat": false,
      "stack": "system",
      "platform": {
        "http_proxy": {
          "enabled": true,
          "server": "0.0.0.0",
          "server_port": 2080
        }
      }
    },
    {
      "type": "mixed",
      "listen": "0.0.0.0",
      "listen_port": 2080,
      "sniff": true,
      "users": []
    }
  ],
  "outbounds": [
    {
      "tag": "$SB_ALL_PROTOCOL_OUT_TAG",
      "type": "$SB_ALL_PROTOCOL_OUT_TYPE",
      "outbounds": [
        "auto",
        "direct",
        "$SB_V_PROTOCOL_OUT_TAG",
        "$SB_VM_PROTOCOL_OUT_TAG"
      ]
    },
    {
      "type": "$V_PROTOCOL",
      "tag": "$SB_V_PROTOCOL_OUT_TAG",
      "uuid": "$V_UUID",
      "flow": "xtls-rprx-vision",
      "packet_encoding": "xudp",
      "server": "$VLESS_N_DOMAIN",
      "server_port": $VLESS_N_PORT,
      "tls": {
        "enabled": true,
        "server_name": "$R_STEAL_WEBSITE_CERTIFICATES",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
        "reality": {
          "enabled": true,
          "public_key": "$R_PUBLICKEY",
          "short_id": "$R_HEX"
        }
      }
    },
    {
      "server": "$R_STEAL_WEBSITE_CERTIFICATES",
      "server_port": $CLOUDFLAREST_PORT,
      "tag": "$SB_VM_PROTOCOL_OUT_TAG",
      "tls": {
        "enabled": true,
        "server_name": "$CLOUDFLARED_DOMAIN",
        "insecure": true,
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        }
      },
      "packet_encoding": "packetaddr",
      "transport": {
        "headers": {
          "Host": [
            "$CLOUDFLARED_DOMAIN"
          ]
        },
        "path": "$WS_PATH",
        "type": "$VM_TYPE",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "type": "$VM_PROTOCOL",
      "security": "auto",
      "uuid": "$VM_UUID"
    },
    {
      "tag": "direct",
      "type": "direct"
    },
    {
      "tag": "block",
      "type": "block"
    },
    {
      "tag": "dns-out",
      "type": "dns"
    },
    {
      "tag": "auto",
      "type": "urltest",
      "outbounds": [
        "$SB_V_PROTOCOL_OUT_TAG",
        "$SB_VM_PROTOCOL_OUT_TAG"
      ],
      "url": "http://www.gstatic.com/generate_204",
      "interval": "1m",
      "tolerance": 50
    },
    {
      "tag": "WeChat",
      "type": "selector",
      "outbounds": [
        "direct",
        "$SB_V_PROTOCOL_OUT_TAG",
        "$SB_VM_PROTOCOL_OUT_TAG"
      ]
    },
    {
      "tag": "Apple",
      "type": "selector",
      "outbounds": [
        "direct",
        "$SB_V_PROTOCOL_OUT_TAG",
        "$SB_VM_PROTOCOL_OUT_TAG"
      ]
    },
    {
      "tag": "Microsoft",
      "type": "selector",
      "outbounds": [
        "direct",
        "$SB_V_PROTOCOL_OUT_TAG",
        "$SB_VM_PROTOCOL_OUT_TAG"
      ]
    }
  ]
}
SMALLFLOWERCAT1995
		cat <<SMALLFLOWERCAT1995 | sudo tee result.txt >/dev/null
SSH is accessible at: 
$HOSTNAME_IP:22 -> $SSH_N_DOMAIN:$SSH_N_PORT
ssh -p $SSH_N_PORT -o ServerAliveInterval=60 $USER_NAME@$SSH_N_DOMAIN

VLESS is accessible at: 
$HOSTNAME_IP:$V_PORT -> $VLESS_N_DOMAIN:$VLESS_N_PORT

VMESS is accessible at: 
$HOSTNAME_IP:$VM_PORT -> $VMESS_N_DOMAIN:$VMESS_N_PORT

Time Frame is accessible at: 
$REPORT_DATE~$F_DATE
SMALLFLOWERCAT1995
		echo "=========================================="
	else
		echo "$HAS_ERRORS"
		exit 6
	fi
}
initall
V_PROTOCOL=vless
V_PROTOCOL_IN_TAG=$V_PROTOCOL-in
V_PORT=$(get_random_port 0 65535)
R_STEAL_WEBSITE_CERTIFICATES=youjizz.com
R_STEAL_WEBSITE_PORT=443
VM_PROTOCOL=vmess
VM_PROTOCOL_IN_TAG=$V_PROTOCOL-in
VM_PORT=$(get_random_port 0 65535)
VM_TYPE=ws
SB_ALL_PROTOCOL_OUT_TAG=sing-box-all-proxy
SB_ALL_PROTOCOL_OUT_TYPE=selector
SB_V_PROTOCOL_OUT_TAG=$V_PROTOCOL-out
SB_VM_PROTOCOL_OUT_TAG=$VM_PROTOCOL-out
CLOUDFLAREST_PORT=443
HOSTNAME_IP=$(hostname -I)
REPORT_DATE=$(TZ=':Asia/Shanghai' date +'%Y-%m-%d %T')
F_DATE=$(date -d '${REPORT_DATE}' --date='6 hour' +'%Y-%m-%d %T')
createUserNamePassword
getStartSing-box_cloudflared_ngrok
rm -fv set-sing-box.sh
