#!/usr/bin/env bash
# 前戏处理
initall(){
    # 同步时间
    date '+%Y-%m-%d %H:%M:%S'
    sudo ln -sfv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    sudo cat << EOL | sudo tee /etc/timezone
    Asia/Shanghai
    EOL
    date '+%Y-%m-%d %H:%M:%S'

    # 安装必备工具
    sudo apt update ; sudo apt-get install -y aria2 catimg git locales curl wget tar socat qrencode uuid net-tools jq

    # clone udp tcp 互转工具
    #sudo git clone https://github.com/mullvad/udp-over-tcp.git ; cd udp-over-tcp
    #sudo bash build-static-bins.sh
    #sudo mv -fv $(find . -iname "tcp2udp") /usr/bin/
    #sudo mv -fv $(find . -iname "udp2tcp") /usr/bin/
    #cd -
    #sudo rm -rfv udp-over-tcp
    sudo wget --verbose --show-progress=on --progress=bar --hsts-file=/tmp/wget-hsts --continue --retry-connrefused --waitretry=1 --timeout=30 --tries=3 "https://github.com/smallflowercat1995/Sing-Box-Ubuntu-Actions-Workflow/raw/master/tcp2udp" -O /usr/bin/tcp2udp ; sudo chmod -v +x /usr/bin/tcp2udp
    sudo wget --verbose --show-progress=on --progress=bar --hsts-file=/tmp/wget-hsts --continue --retry-connrefused --waitretry=1 --timeout=30 --tries=3 "https://github.com/smallflowercat1995/Sing-Box-Ubuntu-Actions-Workflow/raw/master/udp2tcp" -O /usr/bin/udp2tcp ; sudo chmod -v +x /usr/bin/udp2tcp

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
}

# 给变量赋值一个随机的非占用端口
get_random_port(){
    #指定端口范围
    min=$1
    max=$2
    #生成一个随机端口
    port=$(sudo shuf -i $min-$max -n1)
    #检查端口是否被占用
    tcp=$(sudo netstat -an | grep ":$port " | awk '$1 == "tcp" && $NF == "LISTEN" {print $0}' | wc -l)
    udp=$(sudo netstat -an | grep ":$port " | awk '$1 == "udp" && $NF == "0.0.0.0:*" {print $0}' | wc -l)
    #如果端口被占用，重复上述步骤，直到找到一个空闲的端口
    while [ $((tcp + udp)) -gt 0 ]; do
        port=$(sudo shuf -i $min-$max -n1)
        tcp=$(sudo netstat -an | grep ":$port " | awk '$1 == "tcp" && $NF == "LISTEN" {print $0}' | wc -l)
        udp=$(sudo netstat -an | grep ":$port " | awk '$1 == "udp" && $NF == "0.0.0.0:*" {print $0}' | wc -l)
    done
    #返回端口号
    echo $port
}

#实现 TCP UDP端口监听互转的函数
u2t_t2u(){
    # 检查程序是否存在
    if ! command -v udp2tcp &> /dev/null
    then
        echo "udp2tcp is not installed. Please install it first."
        exit 1
    fi

    if ! command -v tcp2udp &> /dev/null
    then
        echo "tcp2udp is not installed. Please install it first."
        exit 1
    fi

    #指定UDP端口和TCP端口
    UDP_PORT=$1
    TCP_PORT=$2

    # 定义 tcp2udp 的 TCP 监听地址和 UDP 转发地址
    TCP_LISTEN_ADDR="0.0.0.0:$TCP_PORT"
    UDP_FORWARD_ADDR="127.0.0.1:$UDP_PORT"

    #创建一个后台进程，监听tcp的源端口，转发给udp的目标端口
    nohup tcp2udp --tcp-listen $TCP_LISTEN_ADDR --udp-forward $UDP_FORWARD_ADDR > /dev/null 2>&1 & disown

    # 定义udp2tcp的UDP监听地址和TCP转发地址
    UDP_LISTEN_ADDR="0.0.0.0:$UDP_PORT"
    TCP_FORWARD_ADDR="127.0.0.1:$TCP_PORT"

    #创建一个后台进程，监听udp的目标端口，转发给tcp的源端口
    nohup udp2tcp --udp-listen $UDP_LISTEN_ADDR --tcp-forward $TCP_FORWARD_ADDR > /dev/null 2>&1 & disown

    #显示后台进程的PID，方便结束时杀死
    echo "TCP to UDP: $TCP_LISTEN_ADDR -> $UDP_FORWARD_ADDR"
    echo "UDP to TCP: $UDP_FORWARD_ADDR -> $TCP_LISTEN_ADDR"
}

# 创建用户添加密码
createUserNamePassword(){
    # 判断用户名
    if [[ -z "${USER_NAME}" ]]; then
        echo "Please set 'USER_NAME' for linux"
        exit 2
    else
        sudo useradd -m ${USER_NAME}
        sudo adduser ${USER_NAME} sudo
    fi

    # 判断设置用户密码环境变量
    if [[ -z "${USER_PW}" ]]; then
        echo "Please set 'USER_PW' for linux"
        exit 3
    else
        echo "${USER_NAME}:${USER_PW}" | sudo chpasswd
        sudo sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
        echo "Update linux user password !"
        echo -e "${USER_PW}\n${USER_PW}" | sudo passwd "${USER_NAME}"
    fi

    # 判断用户hostname
    if [[ -z "${HOST_NAME}" ]]; then
        echo "Please set 'HOST_NAME' for linux"
        exit 4
    else
        sudo hostname ${HOST_NAME}
    fi
}

# 获取配置启动ngrok 和 sing-box
getStartSing-box_cloudflared_CloudflareSpeedTest_ngrok(){
    # 系统架构判断 
    ARCH_RAW=$(uname -m)
    case "${ARCH_RAW}" in
        'x86_64')    ARCH='amd64';;
        'x86' | 'i686' | 'i386')     ARCH='386';;
        'aarch64' | 'arm64') ARCH='arm64';;
        'armv7l')   ARCH='armv7';;
        's390x')    ARCH='s390x';;
        *)          echo "Unsupported architecture: ${ARCH_RAW}"; exit 1;;
    esac

    # 获取Sing-box下载路径
    # https://github.com/SagerNet/sing-box/releases
    # 获取版本
    VERSION=$(curl -sL "https://github.com/SagerNet/sing-box/releases" | grep -oP '(?<=\/SagerNet\/sing-box\/releases\/tag\/)[^"]+' | head -n 1) ; echo ${VERSION}
    #拼接链接
    URI_DOWNLOAD="https://github.com/SagerNet/sing-box/releases/download/${VERSION}/sing-box_${VERSION#v}_$(uname -s)_${ARCH}.deb" ; echo ${URI_DOWNLOAD}
    # 文件名
    FILE_NAME=$(basename ${URI_DOWNLOAD}) ; echo ${FILE_NAME}
    # 下载安装包
    wget --verbose --show-progress=on --progress=bar --hsts-file=/tmp/wget-hsts -c "${URI_DOWNLOAD}" -O ${FILE_NAME}
    # 安装
    sudo dpkg -i ${FILE_NAME}
    # 清理文件
    rm -fv ${FILE_NAME}

    # 获取cloudflared下载路径
    # https://github.com/cloudflare/cloudflared/releases
    # 版本
    VERSION=$(curl -sL "https://github.com/cloudflare/cloudflared/releases" | grep -oP '(?<=\/cloudflare\/cloudflared\/releases\/tag\/)[^"]+' | head -n 1) ; echo ${VERSION}
    # 拼接下载链接
    URI_DOWNLOAD="https://github.com/cloudflare/cloudflared/releases/download/${VERSION}/cloudflared-$(uname -s)-${ARCH}.deb" ; echo ${URI_DOWNLOAD}
    # 截取文件名
    FILE_NAME=$(basename ${URI_DOWNLOAD}) ; echo ${FILE_NAME}
    # 断点续传下载文件
    wget --verbose --show-progress=on --progress=bar --hsts-file=/tmp/wget-hsts -c "${URI_DOWNLOAD}" -O ${FILE_NAME}
    # 安装文件
    sudo dpkg -i ${FILE_NAME}
    # 清理文件
    rm -fv ${FILE_NAME}
    sudo mkdir -pv /home/${USER_NAME}/cloudflared

    # 获取CloudflareSpeedTest下载路径
    # https://github.hscsec.cn/XIU2/CloudflareSpeedTest/releases
    # 获取版本
    VERSION=$(curl -sL "https://github.hscsec.cn/XIU2/CloudflareSpeedTest/releases" | grep -oP '(?<=\/XIU2\/CloudflareSpeedTest\/releases\/tag\/)[^"]+' | head -n 1) ; echo ${VERSION}
    #拼接链接
    URI_DOWNLOAD="https://github.hscsec.cn/XIU2/CloudflareSpeedTest/releases/download/${VERSION}/CloudflareST_$(uname -s)_${ARCH}.tar.gz" ; echo ${URI_DOWNLOAD}
    # 文件名
    FILE_NAME=$(basename ${URI_DOWNLOAD}) ; echo ${FILE_NAME}
    # 下载安装包
    wget --verbose --show-progress=on --progress=bar --hsts-file=/tmp/wget-hsts -c "${URI_DOWNLOAD}" -O ${FILE_NAME}
    # 安装
    sudo mkdir -pv /home/${USER_NAME}/CloudflareSpeedTest ; sudo sudo tar zxvf ${FILE_NAME} -C /home/${USER_NAME}/CloudflareSpeedTest
    # 清理文件
    rm -fv ${FILE_NAME}
    cd /home/${USER_NAME}/CloudflareSpeedTest
    # 优选IP
    CLOUDFLAREST_IP=$(sudo ./CloudflareST -dd -tll 90 | head -n 5 | tail -n 1 | awk '{print $1}')
    cd -
    sudo rm -rfv /home/${USER_NAME}/CloudflareSpeedTest
    if [ "${CLOUDFLAREST_IP}" != "" ];then
        echo ${CLOUDFLAREST_IP}
    else
        CLOUDFLAREST_IP=icook.hk
    fi

    # 判断 Ngrok TOKEN 环境变量
    if [[ -z "${NGROK_AUTH_TOKEN}" ]]; then
        echo "Please set 'NGROK_AUTH_TOKEN'"
        exit 5
    else
        # Ngrok安装
        curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt install ngrok

# ngrok配置文件生成
cat << EOL | sudo tee /home/${USER_NAME}/ngrok/ngrok.yml > /dev/null
authtoken: ${NGROK_AUTH_TOKEN}

tunnels:
  ssh:
    proto: tcp
    addr: 22

  vless:
    proto: tcp
    addr: ${V_PORT}

  vmess:
    proto: tcp
    addr: ${VM_PORT}

  sing-box:
    proto: tcp
    addr: ${U_FORWORD_T_PORT}
EOL
      
    # 应用 ngrok 配置
    sudo ngrok config upgrade --config /home/${USER_NAME}/ngrok/ngrok.yml
    # 启动 ngrok
    sudo nohup ngrok start --all --config /home/${USER_NAME}/ngrok/ngrok.yml > /dev/null 2>&1 & disown
    # 等待
    sleep 10
    # 获取 ngrok 映射信息
    NGROK_INFO=$(curl -s http://127.0.0.1:4040/api/tunnels)
    HAS_ERRORS=$(grep "command failed" < /home/${USER_NAME}/ngrok/ngrok.log)

    if [[ -z "$HAS_ERRORS" ]]; then
        echo "=========================================="
        # 获取 ngrok 映射信息
        NGROK_INFO=$(curl -s http://127.0.0.1:4040/api/tunnels)

        # 提取映射端口和域名
        SSH_N_INFO=$(echo "$NGROK_INFO" | jq -r '.tunnels[] | select(.name=="ssh") | .public_url')
        VLESS_N_INFO=$(echo "$NGROK_INFO" | jq -r '.tunnels[] | select(.name=="vless") | .public_url')
        VMESS_N_INFO=$(echo "$NGROK_INFO" | jq -r '.tunnels[] | select(.name=="vmess") | .public_url')
        SINGBOX_N_INFO=$(echo "$NGROK_INFO" | jq -r '.tunnels[] | select(.name=="sing-box") | .public_url')

        # 使用正则表达式提取域名和端口
        SSH_N_DOMAIN=$(echo "$SSH_N_INFO" | awk -F[/:] '{print $4}')
        SSH_N_PORT=$(echo "$SSH_N_INFO" | awk -F[/:] '{print $5}')

        VLESS_N_DOMAIN=$(echo "$VLESS_N_INFO" | awk -F[/:] '{print $4}')
        VLESS_N_PORT=$(echo "$VLESS_N_INFO" | awk -F[/:] '{print $5}')

        VMESS_N_DOMAIN=$(echo "$VMESS_N_INFO" | awk -F[/:] '{print $4}')
        VMESS_N_PORT=$(echo "$VMESS_N_INFO" | awk -F[/:] '{print $5}')

        SINGBOX_N_DOMAIN=$(echo "$SINGBOX_N_INFO" | awk -F[/:] '{print $4}')
        SINGBOX_N_PORT=$(echo "$SINGBOX_N_INFO" | awk -F[/:] '{print $5}')

        # 创建证书和密钥
        sudo mkdir -pv /home/$USER_NAME/hysteria
        sudo openssl ecparam -genkey -name prime256v1 -out /home/$USER_NAME/hysteria/private.key
        sudo openssl req -new -x509 -days 36500 -key /home/$USER_NAME/hysteria/private.key -out /home/$USER_NAME/hysteria/cert.pem -subj "/CN="${SINGBOX_N_DOMAIN}

        # 生成 reality 私钥公钥对
        R_PRIVATEKEY_PUBLICKEY="$(sing-box generate reality-keypair)"
        # 提取私钥
        R_PRIVATEKEY="$(echo $R_PRIVATEKEY_PUBLICKEY | awk '{print $2}')"
        # 提取公钥
        R_PUBLICKEY="$(echo $R_PRIVATEKEY_PUBLICKEY | awk '{print $4}')"

        # 生成 uuid
        V_UUID="$(sing-box generate uuid)"
        VM_UUID="$(sing-box generate uuid)"

        # 生成16位16进制hex
        R_HEX="$(sing-box generate rand --hex 8)"
        VM_HEX="$(sing-box generate rand --hex 8)"
        SB_HEX="$(sing-box generate rand --hex 8)"

        # 生成12位26进制
        WS_PATH="$(sing-box generate rand --hex 6)"

# 生成sing-box配置文件 写入配置文件
cat << EOL | sudo tee /etc/sing-box/config.json > /dev/null
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
      "type": "${V_PROTOCOL}",
      "tag": "${V_PROTOCOL_IN_TAG}",
      "listen": "::",
      "listen_port": ${V_PORT},
      "users": [
        {
          "uuid": "${V_UUID}",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "${R_STEAL_WEBSITE_CERTIFICATES}",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "${R_STEAL_WEBSITE_CERTIFICATES}",
            "server_port": ${R_STEAL_WEBSITE_PORT}
          },
          "private_key": "${R_PRIVATEKEY}",
          "short_id": [
            "${R_HEX}"
          ]
        }
      }
    },
    {
      "sniff": true,
      "sniff_override_destination": true,
      "type": "${VM_PROTOCOL}",
      "tag": "${VM_PROTOCOL_IN_TAG}",
      "listen": "::",
      "listen_port": ${VM_PORT},
      "users": [
        {
          "uuid": "${VM_UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "${VM_TYPE}",
        "path": "${VM_HEX}",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    },
    {
      "sniff": true,
      "sniff_override_destination": true,
      "type": "${SB_PROTOCOL}",
      "tag": "${SB_PROTOCOL_IN_TAG}",
      "listen": "::",
      "listen_port": ${SB_PORT},
      "users": [
        {
          "password": "${SB_HEX}"
        }
      ],
      "tls": {
        "enabled": true,
        "alpn": [
          "${SB_ALPN}"
        ],
        "certificate_path": "/home/$USER_NAME/hysteria/cert.pem",
        "key_path": "/home/$USER_NAME/hysteria/private.key"
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
EOL

    # 启动 sing-box
    sudo systemctl daemon-reload && sudo systemctl enable --now sing-box && sudo systemctl restart sing-box
    # 启动 cloudflared
    sudo nohup cloudflared tunnel --url http://localhost:${VM_PORT} --no-autoupdate --edge-ip-version auto --protocol http2|sudo tee /home/${USER_NAME}/cloudflared/cloudflared.log 2>&1 & disown
    CLOUDFLARED_DOMAIN="$(cat /home/${USER_NAME}/cloudflared/cloudflared.log | grep trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')"
    if [ "${CLOUDFLARED_DOMAIN}" != "" ];then
        echo ${CLOUDFLARED_DOMAIN}
    else
        CLOUDFLARED_DOMAIN=${VMESS_N_DOMAIN}
    fi
# 反向生成客户端配置 写入内容
cat << EOL | sudo tee client-config.json > /dev/null
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
        "detour": "${SB_ALL_PROTOCOL_OUT_TAG}"
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
    "final": "${SB_ALL_PROTOCOL_OUT_TAG}",
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
        "outbound": "${SB_ALL_PROTOCOL_OUT_TAG}"
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
        "outbound": "${SB_ALL_PROTOCOL_OUT_TAG}"
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
      "tag": "${SB_ALL_PROTOCOL_OUT_TAG}",
      "type": "${SB_ALL_PROTOCOL_OUT_TYPE}",
      "outbounds": [
        "auto",
        "direct",
        "${SB_V_PROTOCOL_OUT_TAG}",
        "${SB_VM_PROTOCOL_OUT_TAG}",
        "${SB_H_PROTOCOL_OUT_TAG}"
      ]
    },
    {
      "type": "${V_PROTOCOL}",
      "tag": "${SB_V_PROTOCOL_OUT_TAG}",
      "uuid": "${V_UUID}",
      "flow": "xtls-rprx-vision",
      "packet_encoding": "xudp",
      "server": "${VLESSREALITY_N_DOMAIN}",
      "server_port": ${VLESSREALITY_N_PORT},
      "tls": {
        "enabled": true,
        "server_name": "${R_STEAL_WEBSITE_CERTIFICATES}",
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
    },
    {
      "server": "${CLOUDFLAREST_IP}",
      "server_port": ${CLOUDFLAREST_PORT},
      "tag": "${SB_VM_PROTOCOL_OUT_TAG}",
      "tls": {
        "enabled": true,
        "server_name": "${CLOUDFLARED_DOMAIN}",
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
            "${CLOUDFLARED_DOMAIN}"
          ]
        },
        "path": "${WS_PATH}",
        "type": "${VM_TYPE}",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "type": "${VM_PROTOCOL}",
      "security": "auto",
      "uuid": "${VM_UUID}"
    },
    {
      "type": "${SB_PROTOCOL}",
      "server": "${SINGBOX_N_DOMAIN}",
      "server_port": ${SINGBOX_N_PORT},
      "tag": "${SB_H_PROTOCOL_OUT_TAG}",
      "up_mbps": 100,
      "down_mbps": 100,
      "password": "${SB_HEX}",
      "tls": {
        "enabled": true,
        "server_name": "${SINGBOX_N_DOMAIN}",
        "insecure": true,
        "alpn": [
          "h3"
        ]
      }
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
        "${SB_V_PROTOCOL_OUT_TAG}",
        "${SB_H_PROTOCOL_OUT_TAG}",
        "${SB_VM_PROTOCOL_OUT_TAG}"
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
        "${SB_V_PROTOCOL_OUT_TAG}",
        "${SB_H_PROTOCOL_OUT_TAG}",
        "${SB_VM_PROTOCOL_OUT_TAG}"
      ]
    },
    {
      "tag": "Apple",
      "type": "selector",
      "outbounds": [
        "direct",
        "${SB_V_PROTOCOL_OUT_TAG}",
        "${SB_H_PROTOCOL_OUT_TAG}",
        "${SB_VM_PROTOCOL_OUT_TAG}"
      ]
    },
    {
      "tag": "Microsoft",
      "type": "selector",
      "outbounds": [
        "direct",
        "${SB_V_PROTOCOL_OUT_TAG}",
        "${SB_H_PROTOCOL_OUT_TAG}",
        "${SB_VM_PROTOCOL_OUT_TAG}"
      ]
    }
  ]
}
EOL

      # UDP TCP 互转端口
      UDP2TCP_INFO=$(u2t_t2u ${SB_PORT} ${U_FORWORD_T_PORT})
cat << EOL | sudo tee result.txt > /dev/null
SSH is accessible at: 
${HOSTNAME_IP}:22 -> ${SSH_N_DOMAIN}:${SSH_N_PORT}
ssh -p ${SSH_N_PORT} -o ServerAliveInterval=60 ${USER_NAME}@${SSH_N_DOMAIN}

VLESS is accessible at: 
${HOSTNAME_IP}:${V_PORT} -> ${VLESS_N_DOMAIN}:${VLESS_N_PORT}

VMESS is accessible at: 
${HOSTNAME_IP}:${VM_PORT} -> ${VMESS_N_DOMAIN}:${VMESS_N_PORT}

Sing-Box is accessible at: 
${HOSTNAME_IP}:${SB_PORT} -> ${SINGBOX_N_DOMAIN}:${SINGBOX_N_PORT}

Time Frame is accessible at: 
${REPORT_DATE}~${F_DATE}
${UDP2TCP_INFO}
EOL

        echo "=========================================="
    else
        echo "$HAS_ERRORS"
        exit 6
    fi
}

initall

# vless
V_PROTOCOL=vless
V_PROTOCOL_IN_TAG=${V_PROTOCOL}-in
V_PORT=$(get_random_port 0 65535)

R_STEAL_WEBSITE_CERTIFICATES=www.youjizz.com
R_STEAL_WEBSITE_PORT=443

# vmess
VM_PROTOCOL=vmess
VM_PROTOCOL_IN_TAG=${V_PROTOCOL}-in
VM_PORT=$(get_random_port 0 65535)
VM_TYPE=ws

# hysteria2
SB_PROTOCOL=hysteria2
SB_PROTOCOL_IN_TAG=${SB_PROTOCOL}-in
# UDP 端口
SB_PORT=$(get_random_port 0 65535)
# TCP 端口
U_FORWORD_T_PORT=$(get_random_port 0 65535)
SB_ALPN=h3
SB_ALL_PROTOCOL_OUT_TAG=sing-box-all-proxy
SB_ALL_PROTOCOL_OUT_TYPE=selector
SB_V_PROTOCOL_OUT_TAG=${V_PROTOCOL}-out
SB_VM_PROTOCOL_OUT_TAG=${VM_PROTOCOL}-out
SB_H_PROTOCOL_OUT_TAG=${SB_PROTOCOL}-out

# 优选IP默认端口
CLOUDFLAREST_PORT=443
# 当前IP
HOSTNAME_IP=$(hostname -I)


# 起止时间环境
REPORT_DATE=$(TZ=':Asia/Shanghai' date +'%Y-%m-%d %T')
F_DATE=$(date -d '${REPORT_DATE}' --date='6 hour' +'%Y-%m-%d %T')

createUserNamePassword
getStartSing-box_cloudflared_CloudflareSpeedTest_ngrok

rm -fv set-sing-box.sh
