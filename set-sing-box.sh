#!/usr/bin/env bash
# 前戏初始化函数 initall
initall() {
    # 更新源
    sudo apt update
    sudo apt -y install ntpdate
    # 获取当前日期
    echo 老时间$(date '+%Y-%m-%d %H:%M:%S')
    # 修改地点时区软连接
    sudo ln -sfv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    # 写入地点时区配置文件
    sudo cat << SMALLFLOWERCAT1995 | sudo tee /etc/timezone
Asia/Shanghai
SMALLFLOWERCAT1995
    sudo cat << SMALLFLOWERCAT1995 | sudo tee /etc/cron.daily/ntpdate
ntpdata ntp.ubuntu.com cn.pool.ntp.org
SMALLFLOWERCAT1995
    sudo chmod -v 7777 /etc/cron.daily/ntpdate
    sudo ntpdate -d cn.pool.ntp.org
    # 重新获取修改地点时区后的时间
    echo 新时间$(date '+%Y-%m-%d %H:%M:%S')
    # 起始时间
    REPORT_DATE="$(TZ=':Asia/Shanghai' date +'%Y-%m-%d %T')"
    # 安装可能会用到的工具
    sudo apt-get install -y aria2 catimg git locales curl wget tar socat qrencode uuid net-tools jq
    # 配置简体中文字符集支持
    sudo perl -pi -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen
    sudo perl -pi -e 's/en_GB.UTF-8 UTF-8/# en_GB.UTF-8 UTF-8/g' /etc/locale.gen
    sudo locale-gen zh_CN
    sudo locale-gen zh_CN.UTF-8
    # 将简体中文字符集支持写入到环境变量
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
    # 检查字符集支持
    locale
    locale -a
    cat /etc/default/locale
    # 应用中文字符集环境编码
    source /etc/environment $HOME/.bashrc $HOME/.profile
}
# 生成随机不占用的端口函数 get_random_port
get_random_port() {
    # 初始端口获取
    min=$1
    # 终末端口获取
    max=$2
    # 在 min~max 范围内生成随机排列端口并获取其中一个
    port=$(sudo shuf -i $min-$max -n1)
    # 从网络状态信息中获取全部连接和监听端口，并将所有的 端口 和 IP 以数字形式显示
    # 过滤出包含特定端口号 :$port
    # 使用 awk 进行进一步的过滤，只打印出第一个字段协议是 TCP 且最后一个字段状态为 LISTEN 的行。
    # 计算输出的行数，从而得知特定端口上正在侦听的 TCP 连接数量
    tcp=$(sudo netstat -an | grep ":$port " | awk '$1 == "tcp" && $NF == "LISTEN" {print $0}' | wc -l)
    # 从网络状态信息中获取全部连接和监听端口，并将所有的 端口 和 IP 以数字形式显示
    # 过滤出包含特定端口号 :$port
    # 使用 awk 进行进一步的过滤，只打印出第一个字段协议是 UDP 且最后一个字段状态为 LISTEN 的行。
    # 计算输出的行数，从而得知特定端口上正在侦听的 UDP 连接数量
    udp=$(sudo netstat -an | grep ":$port " | awk '$1 == "udp" && $NF == "0.0.0.0:*" {print $0}' | wc -l)
    # 判断 tcp 连接数 + udp 连接数是否大于0，大于0则证明端口占用，继续以下步骤
    # 从网络状态信息中获取全部连接和监听端口，并将所有的 端口 和 IP 以数字形式显示
    # 过滤出包含特定端口号 :$port
    # 使用 awk 进行进一步的过滤，只打印出第一个字段协议是 TCP/UDP 且最后一个字段状态为 LISTEN 的行。
    # 计算输出的行数，从而得知特定端口上正在侦听的 TCP/UDP 连接数量
    while [ $((tcp + udp)) -gt 0 ]; do
        port=$(sudo shuf -i $min-$max -n1)
        tcp=$(sudo netstat -an | grep ":$port " | awk '$1 == "tcp" && $NF == "LISTEN" {print $0}' | wc -l)
        udp=$(sudo netstat -an | grep ":$port " | awk '$1 == "udp" && $NF == "0.0.0.0:*" {print $0}' | wc -l)
    done
    # 输出不占用任何端口的数值
    echo $port
}
# 初始化用户密码
createUserNamePassword() {
    # 判断 USER_NAME 变量是否在 actions 环境中存在
    # 不存在则打印提示并退出，返回一个退出号
    # 存在则添加 USER_NAME 变量用户，将用户添加到 sudo 组
    if [[ -z "$USER_NAME" ]]; then
        echo "Please set 'USER_NAME' for linux"
        exit 2
    else
        sudo useradd -m $USER_NAME
        sudo adduser $USER_NAME sudo
    fi
    # 判断 USER_PW 变量是否在 actions 环境中存在
    # 不存在则打印提示并退出，返回一个退出号
    # 存在则执行以下步骤
    # 将通过管道将用户名和密码传递给 chpasswd 更改用户密码
    # 使用 sed 工具在 "/etc/passwd" 文件中将所有 "/bin/sh" 替换为 "/bin/bash"
    # 打印提示信息
    # 以防万一，通过管道将两次输入的密码传递给 passwd 命令，以更新用户的密码
    if [[ -z "$USER_PW" ]]; then
        echo "Please set 'USER_PW' for linux"
        exit 3
    else
        echo "$USER_NAME:$USER_PW" | sudo chpasswd
        sudo sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
        echo "Update linux user password !"
        echo -e "$USER_PW\n$USER_PW" | sudo passwd "$USER_NAME"
    fi
    # 判断 HOST_NAME 变量是否在 actions 环境中存在
    # 不存在则打印提示并退出，返回一个退出号
    # 存在则设置 hostname 变量
    if [[ -z "$HOST_NAME" ]]; then
        echo "Please set 'HOST_NAME' for linux"
        exit 4
    else
        sudo hostname $HOST_NAME
    fi
    # 执行 sudo 免密码脚本生成
    cat <<EOL | sudo tee test.sh
# 在 /etc/sudoers.d 路径下创建一个 USER_NAME 变量的文件
sudo touch /etc/sudoers.d/$USER_NAME
# 给文件更改使用者和使用组 USER_NAME 变量
sudo chown -Rv $USER_NAME:$USER_NAME /etc/sudoers.d/$USER_NAME
# 给文件更改可读写执行的权限 777
sudo chmod -Rv 0777 /etc/sudoers.d/$USER_NAME
# 允许 USER_NAME 用户在执行sudo时无需输入密码，写入到文件
echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" | sudo tee > /etc/sudoers.d/$USER_NAME
# 给文件更改使用者和使用组 root
sudo chown -Rv root:root  /etc/sudoers.d/$USER_NAME
# 给文件更改 root 可读 USER_NAME 可读 其他用户无权限 0440
sudo chmod -Rv 0440 /etc/sudoers.d/$USER_NAME
# 打印文件信息
sudo cat /etc/sudoers.d/$USER_NAME
EOL
    # 以 sudo 权限执行免密码脚本并删除
    sudo bash -c "bash test.sh ; rm -rfv test.sh"
}
# 下载 CloudflareSpeedTest sing-box cloudflared ngrok 配置并启用
getAndStart() {
    # 启用 TCP BBR 拥塞控制算法，参考 https://github.com/teddysun/across
    sudo su root bash -c "bash <(curl -L -s https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)"
    # 判断系统 cpu 架构 ARCH_RAW ，并重新赋值架构名 ARCH
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

    # github 项目 XIU2/CloudflareSpeedTest
    URI="XIU2/CloudflareSpeedTest"
    # 从 XIU2/CloudflareSpeedTest github中提取全部 tag 版本，获取最新版本赋值给 VERSION 后打印
    VERSION=$(curl -sL "https://github.com/$URI/releases" | grep -oP '(?<=\/releases\/tag\/)[^"]+' | head -n 1)
    echo $VERSION
    # 拼接下载链接 URI_DOWNLOAD 后打印
    URI_DOWNLOAD="https://github.com/$URI/releases/download/$VERSION/CloudflareST_$(uname -s)_$ARCH.tar.gz"
    echo $URI_DOWNLOAD
    # 获取文件名 FILE_NAME 后打印
    FILE_NAME=$(basename $URI_DOWNLOAD)
    echo $FILE_NAME
    # 下载文件，可续传并打印进度
    wget --verbose --show-progress=on --progress=bar --hsts-file=/tmp/wget-hsts -c "$URI_DOWNLOAD" -O $FILE_NAME
    # 创建目录 /home/$USER_NAME/CloudflareST
    sudo mkdir -pv /home/$USER_NAME/${FILE_NAME%%_$(uname -s)_$ARCH.tar.gz}
    # 解压项目到目录 /home/$USER_NAME/CloudflareST
    sudo tar xzvf $FILE_NAME -C /home/$USER_NAME/${FILE_NAME%%_$(uname -s)_$ARCH.tar.gz}
    # 执行测速命令，返回优选 ip
    cd /home/$USER_NAME/${FILE_NAME%%_$(uname -s)_$ARCH.tar.gz}
    VM_WEBSITE=$(./CloudflareST -dd -tll 90 -p 1 -o "" | tail -n1 | awk '{print $1}')
    cd -
    # 删除文件
    sudo rm -rfv $FILE_NAME /home/$USER_NAME/${FILE_NAME%%_$(uname -s)_$ARCH.tar.gz}

    # github 项目 SagerNet/sing-box
    URI="SagerNet/sing-box"
    # 从 SagerNet/sing-box 官网中提取全部 tag 版本，获取最新版本赋值给 VERSION 后打印
    VERSION=$(curl -sL "https://github.com/$URI/releases" | grep -oP '(?<=\/releases\/tag\/)[^"]+' | head -n 1)
    echo $VERSION
    # 拼接下载链接 URI_DOWNLOAD 后打印
    URI_DOWNLOAD="https://github.com/$URI/releases/download/$VERSION/sing-box_${VERSION#v}_$(uname -s)_$ARCH.deb"
    echo $URI_DOWNLOAD
    # 获取文件名 FILE_NAME 后打印
    FILE_NAME=$(basename $URI_DOWNLOAD)
    echo $FILE_NAME
    # 下载文件，可续传并打印进度
    wget --verbose --show-progress=on --progress=bar --hsts-file=/tmp/wget-hsts -c "$URI_DOWNLOAD" -O $FILE_NAME
    # 安装文件
    sudo dpkg -i $FILE_NAME
    # 删除文件
    rm -fv $FILE_NAME

    # github 项目 cloudflare/cloudflared
    URI="cloudflare/cloudflared"
    # 从 cloudflare/cloudflared 官网中提取全部 tag 版本，获取最新版本赋值给 VERSION 后打印
    VERSION=$(curl -sL "https://github.com/$URI/releases" | grep -oP '(?<=\/releases\/tag\/)[^"]+' | head -n 1)
    echo $VERSION
    # 拼接下载链接 URI_DOWNLOAD 后打印
    URI_DOWNLOAD="https://github.com/$URI/releases/download/$VERSION/cloudflared-$(uname -s)-$ARCH.deb"
    echo $URI_DOWNLOAD
    # 获取文件名 FILE_NAME 后打印
    FILE_NAME=$(basename $URI_DOWNLOAD)
    echo $FILE_NAME
    # 下载文件，可续传并打印进度
    wget --verbose --show-progress=on --progress=bar --hsts-file=/tmp/wget-hsts -c "$URI_DOWNLOAD" -O $FILE_NAME
    # 创建目录 /home/$USER_NAME/cloudflared
    sudo mkdir -pv /home/$USER_NAME/${FILE_NAME%%-$(uname -s)-$ARCH.deb}
    # 安装文件
    sudo dpkg -i $FILE_NAME
    # 删除文件
    rm -fv $FILE_NAME

    # 判断 NGROK_AUTH_TOKEN 变量是否在 actions 环境中存在
    # 不存在则打印提示并退出，返回一个退出号
    # 存在则执行 ngrok 安装
    if [[ -z "$NGROK_AUTH_TOKEN" ]]; then
        echo "Please set 'NGROK_AUTH_TOKEN'"
        exit 5
    else
        curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt install ngrok
        sudo mkdir -pv /home/$USER_NAME/ngrok
        # 执行函数 get_random_port 传入端口号范围，赋值给 V_PORT
        V_PORT="$(get_random_port 0 65535)"
        # 执行函数 get_random_port 传入端口号范围，赋值给 VM_PORT
        VM_PORT="$(get_random_port 0 65535)"
        # 执行函数 get_random_port 传入端口号范围，赋值给 H2_PORT
        H2_PORT="$(get_random_port 0 65535)"
        # 写入 ngrok 配置文件，包含 ngrok 认证 key 、tcp 协议 ssh 端口和 tcp 协议 vless 端口
        cat <<SMALLFLOWERCAT1995 | sudo tee /home/$USER_NAME/ngrok/ngrok.yml >/dev/null
authtoken: $NGROK_AUTH_TOKEN

tunnels:
  ssh:
    proto: tcp
    addr: 22

  vless:
    proto: tcp
    addr: $V_PORT

  hysteria2:
    proto: tcp
    addr: $H2_PORT
SMALLFLOWERCAT1995
        # 更新指定 ngrok 配置文件，添加版本号和网速最快的国家代码
        sudo ngrok config upgrade --config /home/$USER_NAME/ngrok/ngrok.yml
        # 后台启用 ngrok 且让其脱离 shell 终端寿命
        sudo nohup ngrok start --all --config /home/${USER_NAME}/ngrok/ngrok.yml --log /home/${USER_NAME}/ngrok/ngrok.log >/dev/null 2>&1 & disown
        # 睡 10 秒让 ngrok 充分运行
        sleep 10
    fi

    # sing-box 服务器配置所需变量
    # vless 配置所需变量
    # vless 协议
    V_PROTOCOL=vless
    # vless 入站名
    V_PROTOCOL_IN_TAG=$V_PROTOCOL-in
    # sing-box 生成 uuid
    V_UUID="$(sing-box generate uuid)"

    # reality 配置所需变量
    # reality 偷取域名证书，域名需要验证是否支持 TLS 1.3 和 HTTP/2
    R_STEAL_WEBSITE_CERTIFICATES=itunes.apple.com

    # 验证域名是否支持 TLS 1.3 和 HTTP/2
    # while true; do
    #       # 默认 reality_server_name 变量默认值为 itunes.apple.com
    # 	reality_server_name="itunes.apple.com"
    #       # 获得用户输入的域名并赋值给 input_server_name
    # 	read -p "请输入需要的网站，检测是否支持 TLS 1.3 and HTTP/2 (默认: $reality_server_name): " input_server_name
    #       # 赋值给 reality_server_name 变量，如果用户输入为空则是用 reality_server_name 默认值 itunes.apple.com
    # 	reality_server_name=${input_server_name:-$reality_server_name}
    #       # 使用 curl 验证域名是否支持 TLS 1.3 和 HTTP/2
    # 	# 支持则打印信息退出死循环
    #       # 不支持则打印重新进入死循环让用户重新输出新域名
    # 	if curl --tlsv1.3 --http2 -sI "https://$reality_server_name" | grep -q "HTTP/2"; then
    # 		echo "域名 $reality_server_name 支持 TLS 1.3 或 HTTP/2"
    # 		break
    # 	else
    # 		echo "域名 $reality_server_name 不支持 TLS 1.3 或 HTTP/2，请重新输入."
    # 	fi
    # done

    # reality 域名默认端口 443
    R_STEAL_WEBSITE_PORT=443
    # sing-box 生成 reality 公私钥对
    R_PRIVATEKEY_PUBLICKEY="$(sing-box generate reality-keypair)"
    # reality 私钥信息提取
    R_PRIVATEKEY="$(echo $R_PRIVATEKEY_PUBLICKEY | awk '{print $2}')"
    # sing-box 生成 16 位 reality hex
    R_HEX="$(sing-box generate rand --hex 8)"

    # vmess 配置所需变量
    # vmess 协议
    VM_PROTOCOL=vmess
    # vmess 入站名
    VM_PROTOCOL_IN_TAG=$VM_PROTOCOL-in
    # sing-box 生成 uuid
    VM_UUID="$(sing-box generate uuid)"
    # vmess 类型
    VM_TYPE=ws
    # sing-box 生成 12 位 vmess hex 路径
    VM_PATH="$(sing-box generate rand --hex 6)"

    # hysteria2 配置所需变量
    # hysteria2 协议
    H2_PROTOCOL=hysteria2
    # hysteria2 入站名
    H2_PROTOCOL_IN_TAG=$H2_PROTOCOL-in
    # sing-box 生成 16 位 hysteria2 hex
    H2_HEX="$(sing-box generate rand --hex 8)"
    # hysteria2 类型
    H2_TYPE=h3
    # hysteria2 证书域名
    H2_WEBSITE_CERTIFICATES=bing.com
    # sing-box 生成 12 位 vmess hex 路径
    sudo mkdir -pv /home/$USER_NAME/self-cert
    sudo openssl ecparam -genkey -name prime256v1 -out /home/$USER_NAME/self-cert/private.key
    sudo openssl req -new -x509 -days 36500 -key /home/$USER_NAME/self-cert/private.key -out /home/$USER_NAME/self-cert/cert.pem -subj "/CN="$H2_WEBSITE_CERTIFICATES

    # 写入服务器端 sing-box 配置文件
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
          "short_id": ["$R_HEX"]
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
            "path": "$VM_PATH",
            "max_early_data":2048,
            "early_data_header_name":"Sec-WebSocket-Protocol"
        }
    },
    {
        "sniff": true,
        "sniff_override_destination": true,
        "type": "$H2_PROTOCOL",
        "tag": "$H2_PROTOCOL_IN_TAG",
        "listen": "::",
        "listen_port": $H2_PORT,
        "users": [
            {
                "password": "$H2_HEX"
            }
        ],
        "tls": {
            "enabled": true,
            "alpn": [
                "$H2_TYPE"
            ],
            "certificate_path": "/home/$USER_NAME/self-cert/cert.pem",
            "key_path": "/home/$USER_NAME/self-cert/private.key"
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
    # 使用grep命令在 ngrok 日志文件中查找运行失败时包含的 "command failed" 字符串行，并将结果存储在变量 HAS_ERRORS 中
    HAS_ERRORS=$(grep "error" </home/${USER_NAME}/ngrok/ngrok.log)
    # 检查变量HAS_ERRORS是否为空
    # 为空（即没有找到"error"字符串），则执行下一条命令
    # 不为空打印 HAS_ERRORS 内容，返回退出号
    if [[ -z "$HAS_ERRORS" ]]; then
        # 从 ngrok api 中获取必备信息赋值给 NGROK_INFO
        NGROK_INFO="$(curl -s http://127.0.0.1:4040/api/tunnels)"
        # ngrok 日志提取 vless 信息
        VLESS_N_INFO="$(echo "$NGROK_INFO" | jq -r '.tunnels[] | select(.name=="vless") | .public_url')"
        # vless 域名
        VLESS_N_DOMAIN="$(echo "$VLESS_N_INFO" | awk -F[/:] '{print $4}')"
        # vless 端口
        VLESS_N_PORT="$(echo "$VLESS_N_INFO" | awk -F[/:] '{print $5}')"

        # ngrok 日志提取 vmess 信息
        H2_N_INFO="$(echo "$NGROK_INFO" | jq -r '.tunnels[] | select(.name=="hysteria2") | .public_url')"
        # vmess 域名
        H2_N_DOMAIN="$(echo "$H2_N_INFO" | awk -F[/:] '{print $4}')"
        # vmess 端口
        H2_N_PORT="$(echo "$H2_N_INFO" | awk -F[/:] '{print $5}')"

        # ngrok 日志提取 ssh 信息
        SSH_N_INFO="$(echo "$NGROK_INFO" | jq -r '.tunnels[] | select(.name=="ssh") | .public_url')"
        # ssh 连接域名
        SSH_N_DOMAIN="$(echo "$SSH_N_INFO" | awk -F[/:] '{print $4}')"
        # ssh 连接端口
        SSH_N_PORT="$(echo "$SSH_N_INFO" | awk -F[/:] '{print $5}')"
    else
        echo "$HAS_ERRORS"
        # exit 6
        VLESS_N_PORT=$V_PORT
    fi
    # 启动 sing-box 服务
    sudo systemctl daemon-reload && sudo systemctl enable --now sing-box && sudo systemctl restart sing-box
    # 后台启用 cloudflared 获得隧穿日志并脱离 shell 终端寿命
    sudo nohup cloudflared tunnel --url http://localhost:$VM_PORT --no-autoupdate --edge-ip-version auto --protocol http2 >/home/$USER_NAME/cloudflared/cloudflared.log 2>&1 & disown
    # 杀死 cloudflared
    sudo kill -9 $(sudo ps -ef | grep -v grep | grep cloudflared | awk '{print $2}')
    # 再次后台启用 cloudflared 获得隧穿日志并脱离 shell 终端寿命
    sudo nohup cloudflared tunnel --url http://localhost:$VM_PORT --no-autoupdate --edge-ip-version auto --protocol http2 >/home/$USER_NAME/cloudflared/cloudflared.log 2>&1 & disown
    # 睡 5 秒，让 cloudflared 充分运行
    sleep 5
    # sing-box 客户端配置所需变量
    # 出站代理名
    SB_ALL_PROTOCOL_OUT_TAG=proxy
    # 出站类型
    SB_ALL_PROTOCOL_OUT_TYPE=selector
    # vless 出站名
    SB_V_PROTOCOL_OUT_TAG=$V_PROTOCOL-out
    SB_V_PROTOCOL_OUT_TAG_A=$SB_V_PROTOCOL_OUT_TAG-A
    # vmess 出站名
    SB_VM_PROTOCOL_OUT_TAG=$VM_PROTOCOL-out
    SB_VM_PROTOCOL_OUT_TAG_A=$SB_VM_PROTOCOL_OUT_TAG-A
    # hysteria2 出站名
    SB_H2_PROTOCOL_OUT_TAG=$H2_PROTOCOL-out
    SB_H2_PROTOCOL_OUT_TAG_A=$SB_H2_PROTOCOL_OUT_TAG-A
    # reality 公钥信息提取
    R_PUBLICKEY="$(echo $R_PRIVATEKEY_PUBLICKEY | awk '{print $4}')"
    # 默认优选 IP/域名 和 端口，可修改成自己的优选
    # 不为空打印 VM_WEBSITE 域名
    # 为空赋值默认域名后打印
    if [ "$VM_WEBSITE" != "" ]; then
        echo $VM_WEBSITE
    else
        VM_WEBSITE=icook.hk
        echo $VM_WEBSITE
    fi

    # 从 cloudflared 日志中获得遂穿域名
    CLOUDFLARED_DOMAIN="$(cat /home/$USER_NAME/cloudflared/cloudflared.log | grep trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')"
    # 备用判断获取 CLOUDFLARED_DOMAIN 是否为空
    # 不为空打印 cloudflared 域名
    # 为空赋值 ngrok 域名后打印
    # if [ "$CLOUDFLARED_DOMAIN" != "" ]; then
    # 	echo $CLOUDFLARED_DOMAIN
    # else
    # 	CLOUDFLARED_DOMAIN=$VMESS_N_DOMAIN
    # 	echo $CLOUDFLARED_DOMAIN
    # fi
    # cloudflared 默认端口
    CLOUDFLARED_PORT=443
    
    # VLESS 二维码生成扫描文件
    VLESS_LINK="vless://$V_UUID@$VLESS_N_DOMAIN:$VLESS_N_PORT/?type=tcp&encryption=none&flow=xtls-rprx-vision&sni=$R_STEAL_WEBSITE_CERTIFICATES&fp=chrome&security=reality&pbk=$R_PUBLICKEY&sid=$R_HEX&packetEncoding=xudp#$SB_V_PROTOCOL_OUT_TAG_A"
    #qrencode -t UTF8 $VLESS_LINK
    qrencode -o VLESS.png $VLESS_LINK

    # VMESS 二维码生成扫描文件
    VMESS_LINK='vmess://'$(echo '{"add":"'$VM_WEBSITE'","aid":"0","alpn":"","fp":"chrome","host":"'$CLOUDFLARED_DOMAIN'","id":"'$VM_UUID'","net":"'$VM_TYPE'","path":"/'$VM_PATH'?ed\u003d2048","port":"'$CLOUDFLARED_PORT'","ps":"'$SB_VM_PROTOCOL_OUT_TAG_A'","scy":"auto","sni":"'$CLOUDFLARED_DOMAIN'","tls":"tls","type":"","v":"2"}' | base64 -w 0)
    #qrencode -t UTF8 $VMESS_LINK
    qrencode -o VMESS.png $VMESS_LINK

    # HYSTERIA2 二维码生成扫描文件
    HYSTERIA2_LINK="hy2://$H2_HEX@$H2_N_DOMAIN:$H2_N_PORT/?insecure=1&sni=$H2_WEBSITE_CERTIFICATES#$SB_H2_PROTOCOL_OUT_TAG_A"
    #qrencode -t UTF8 $HYSTERIA2_LINK
    qrencode -o HYSTERIA2.png $HYSTERIA2_LINK

    # 写入 nekobox 客户端配置到 client-nekobox-config.yaml 文件
    cat << SMALLFLOWERCAT1995 | sudo tee client-nekobox-config.yaml >/dev/null
port: 7891
socks-port: 7892
mixed-port: 7893
redir-port: 7894
tproxy-port: 7895
bind-address: "*"
allow-lan: true
mode: Rule
log-level: debug
external-controller: 127.0.0.1:9090
clash-for-android:
  append-system-dns: false
hosts:
  mtalk.google.com: 108.177.125.188
dns:
  enable: true
  listen: 127.0.0.1:5335
  use-hosts: true
  default-nameserver: [223.5.5.5, 119.29.29.29]
  ipv6: false
  enhanced-mode: fake-ip
  fake-ip-filter:
    [
      "*.n.n.srv.nintendo.net",
      +.stun.playstation.net,
      xbox.*.*.microsoft.com,
      "*.msftncsi.com",
      "*.msftconnecttest.com",
      WORKGROUP,
      "*.lan",
      stun.*.*.*,
      stun.*.*,
      time.windows.com,
      time.nist.gov,
      time.apple.com,
      time.asia.apple.com,
      "*.ntp.org.cn",
      "*.openwrt.pool.ntp.org",
      time1.cloud.tencent.com,
      time.ustc.edu.cn,
      pool.ntp.org,
      ntp.ubuntu.com,
      "*.*.xboxlive.com",
      speedtest.cros.wr.pvp.net,
    ]
  nameserver:
    [
      tls://223.5.5.5:853,
      https://223.6.6.6/dns-query,
      https://120.53.53.53/dns-query,
    ]
  nameserver-policy:
    {
      +.tmall.com: 223.5.5.5,
      +.taobao.com: 223.5.5.5,
      +.alicdn.com: 223.5.5.5,
      +.aliyun.com: 223.5.5.5,
      +.alipay.com: 223.5.5.5,
      +.alibaba.com: 223.5.5.5,
      +.qq.com: 119.29.29.29,
      +.tencent.com: 119.29.29.29,
      +.weixin.com: 119.29.29.29,
      +.qpic.cn: 119.29.29.29,
      +.jd.com: 119.29.29.29,
      +.bilibili.com: 119.29.29.29,
      +.hdslb.com: 119.29.29.29,
      +.163.com: 119.29.29.29,
      +.126.com: 119.29.29.29,
      +.126.net: 119.29.29.29,
      +.127.net: 119.29.29.29,
      +.netease.com: 119.29.29.29,
      +.baidu.com: 223.5.5.5,
      +.bdstatic.com: 223.5.5.5,
      +.bilivideo.+: 119.29.29.29,
      +.iqiyi.com: 119.29.29.29,
      +.douyinvod.com: 180.184.1.1,
      +.douyin.com: 180.184.1.1,
      +.douyincdn.com: 180.184.1.1,
      +.douyinpic.com: 180.184.1.1,
      +.feishu.cn: 180.184.1.1,
    }
  fallback:
    [
      tls://101.101.101.101:853,
      https://101.101.101.101/dns-query,
      https://public.dns.iij.jp/dns-query,
      https://208.67.220.220/dns-query,
    ]
  fallback-filter:
    {
      geoip: true,
      ipcidr: [240.0.0.0/4, 0.0.0.0/32, 127.0.0.1/32],
      domain:
        [
          +.google.com,
          +.facebook.com,
          +.twitter.com,
          +.youtube.com,
          +.xn--ngstr-lra8j.com,
          +.google.cn,
          +.googleapis.cn,
          +.googleapis.com,
          +.gvt1.com,
          +.paoluz.com,
          +.paoluz.link,
          +.paoluz.xyz,
          +.sodacity-funk.xyz,
          +.nloli.xyz,
          +.jsdelivr.net,
          +.proton.me,
        ],
    }
proxies:
  - name: $SB_V_PROTOCOL_OUT_TAG_A
    type: $V_PROTOCOL
    server: $VLESS_N_DOMAIN
    port: $VLESS_N_PORT
    uuid: $V_UUID
    network: tcp
    udp: true
    tls: true
    flow: xtls-rprx-vision
    servername: $R_STEAL_WEBSITE_CERTIFICATES
    client-fingerprint: chrome
    reality-opts:
      public-key: $R_PUBLICKEY
      short-id: $R_HEX
  - name: $SB_VM_PROTOCOL_OUT_TAG_A
    type: $VM_PROTOCOL
    server: $VM_WEBSITE
    port: $CLOUDFLARED_PORT
    uuid: $VM_UUID
    alterId: 0
    cipher: auto
    udp: true
    tls: true
    client-fingerprint: chrome
    skip-cert-verify: true
    servername: $CLOUDFLARED_DOMAIN
    network: $VM_TYPE
    ws-opts:
      path: /$VM_PATH?ed=2048
      headers:
        Host: $CLOUDFLARED_DOMAIN
  - name: $SB_H2_PROTOCOL_OUT_TAG_A
    type: $H2_PROTOCOL
    server: $H2_N_DOMAIN
    port: $H2_N_PORT
    up: "100 Mbps"
    down: "100 Mbps"
    password: $H2_HEX
    sni: $H2_WEBSITE_CERTIFICATES
    skip-cert-verify: true
    alpn:
      - $H2_TYPE
proxy-groups:
  - name: 🚀 节点选择
    type: select
    proxies:
      - ♻️ 自动选择
      - $SB_V_PROTOCOL_OUT_TAG_A
      - $SB_VM_PROTOCOL_OUT_TAG_A
      - $SB_H2_PROTOCOL_OUT_TAG_A
      - DIRECT
  - name: ♻️ 自动选择
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 3600
    tolerance: 200
    proxies:
      - $SB_V_PROTOCOL_OUT_TAG_A
      - $SB_VM_PROTOCOL_OUT_TAG_A
      - $SB_H2_PROTOCOL_OUT_TAG_A
  - name: 🌍 国外媒体
    type: select
    proxies:
      - 🚀 节点选择
      - 🎯 全球直连
      - $SB_V_PROTOCOL_OUT_TAG_A
      - $SB_VM_PROTOCOL_OUT_TAG_A
      - $SB_H2_PROTOCOL_OUT_TAG_A
  - name: 📲 电报信息
    type: select
    proxies:
      - 🚀 节点选择
      - 🎯 全球直连
      - $SB_V_PROTOCOL_OUT_TAG_A
      - $SB_VM_PROTOCOL_OUT_TAG_A
      - $SB_H2_PROTOCOL_OUT_TAG_A
  - name: Ⓜ️ 微软服务
    type: select
    proxies:
      - 🎯 全球直连
      - 🚀 节点选择
  - name: 🍎 苹果服务
    type: select
    proxies:
      - 🚀 节点选择
      - 🎯 全球直连
  - name: 📢 谷歌FCM
    type: select
    proxies:
      - 🚀 节点选择
      - 🎯 全球直连
  - name: 🎯 全球直连
    type: select
    proxies:
      - DIRECT
      - 🚀 节点选择
  - name: 🍃 应用净化
    type: select
    proxies:
      - REJECT
      - 🚀 节点选择
  - name: 🐟 漏网之鱼
    type: select
    proxies:
      - 🚀 节点选择
      - 🎯 全球直连
      - $SB_V_PROTOCOL_OUT_TAG_A
      - $SB_VM_PROTOCOL_OUT_TAG_A
      - $SB_H2_PROTOCOL_OUT_TAG_A
rules:
  - DOMAIN-SUFFIX,acl4.ssr,🎯 全球直连
  - DOMAIN-SUFFIX,ip6-localhost,🎯 全球直连
  - DOMAIN-SUFFIX,ip6-loopback,🎯 全球直连
  - DOMAIN-SUFFIX,lan,🎯 全球直连
  - DOMAIN-SUFFIX,local,🎯 全球直连
  - DOMAIN-SUFFIX,localhost,🎯 全球直连
  - IP-CIDR,0.0.0.0/8,🎯 全球直连,no-resolve
  - IP-CIDR,10.0.0.0/8,🎯 全球直连,no-resolve
  - IP-CIDR,100.64.0.0/10,🎯 全球直连,no-resolve
  - IP-CIDR,127.0.0.0/8,🎯 全球直连,no-resolve
  - IP-CIDR,172.16.0.0/12,🎯 全球直连,no-resolve
  - IP-CIDR,192.168.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,198.18.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,224.0.0.0/4,🎯 全球直连,no-resolve
  - IP-CIDR6,::1/128,🎯 全球直连,no-resolve
  - IP-CIDR6,fc00::/7,🎯 全球直连,no-resolve
  - IP-CIDR6,fe80::/10,🎯 全球直连,no-resolve
  - IP-CIDR6,fd00::/8,🎯 全球直连,no-resolve
  - DOMAIN,instant.arubanetworks.com,🎯 全球直连
  - DOMAIN,setmeup.arubanetworks.com,🎯 全球直连
  - DOMAIN,router.asus.com,🎯 全球直连
  - DOMAIN,www.asusrouter.com,🎯 全球直连
  - DOMAIN-SUFFIX,hiwifi.com,🎯 全球直连
  - DOMAIN-SUFFIX,leike.cc,🎯 全球直连
  - DOMAIN-SUFFIX,miwifi.com,🎯 全球直连
  - DOMAIN-SUFFIX,my.router,🎯 全球直连
  - DOMAIN-SUFFIX,p.to,🎯 全球直连
  - DOMAIN-SUFFIX,peiluyou.com,🎯 全球直连
  - DOMAIN-SUFFIX,phicomm.me,🎯 全球直连
  - DOMAIN-SUFFIX,router.ctc,🎯 全球直连
  - DOMAIN-SUFFIX,routerlogin.com,🎯 全球直连
  - DOMAIN-SUFFIX,tendawifi.com,🎯 全球直连
  - DOMAIN-SUFFIX,zte.home,🎯 全球直连
  - DOMAIN-SUFFIX,tplogin.cn,🎯 全球直连
  - DOMAIN-SUFFIX,wifi.cmcc,🎯 全球直连
  - DOMAIN-SUFFIX,ol.epicgames.com,🎯 全球直连
  - DOMAIN-SUFFIX,dizhensubao.getui.com,🎯 全球直连
  - DOMAIN,dl.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,googletraveladservices.com,🎯 全球直连
  - DOMAIN-SUFFIX,tracking-protection.cdn.mozilla.net,🎯 全球直连
  - DOMAIN,origin-a.akamaihd.net,🎯 全球直连
  - DOMAIN,fairplay.l.qq.com,🎯 全球直连
  - DOMAIN,livew.l.qq.com,🎯 全球直连
  - DOMAIN,vd.l.qq.com,🎯 全球直连
  - DOMAIN,errlog.umeng.com,🎯 全球直连
  - DOMAIN,msg.umeng.com,🎯 全球直连
  - DOMAIN,msg.umengcloud.com,🎯 全球直连
  - DOMAIN,tracking.miui.com,🎯 全球直连
  - DOMAIN,app.adjust.com,🎯 全球直连
  - DOMAIN,bdtj.tagtic.cn,🎯 全球直连
  - DOMAIN,rewards.hypixel.net,🎯 全球直连
  - DOMAIN-SUFFIX,a.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,adgeo.corp.163.com,🍃 应用净化
  - DOMAIN-SUFFIX,analytics.126.net,🍃 应用净化
  - DOMAIN-SUFFIX,bobo.corp.163.com,🍃 应用净化
  - DOMAIN-SUFFIX,c.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,clkservice.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,conv.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,dsp-impr2.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,dsp.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,fa.corp.163.com,🍃 应用净化
  - DOMAIN-SUFFIX,g.corp.163.com,🍃 应用净化
  - DOMAIN-SUFFIX,g1.corp.163.com,🍃 应用净化
  - DOMAIN-SUFFIX,gb.corp.163.com,🍃 应用净化
  - DOMAIN-SUFFIX,gorgon.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,haitaoad.nosdn.127.net,🍃 应用净化
  - DOMAIN-SUFFIX,iadmatvideo.nosdn.127.net,🍃 应用净化
  - DOMAIN-SUFFIX,img1.126.net,🍃 应用净化
  - DOMAIN-SUFFIX,img2.126.net,🍃 应用净化
  - DOMAIN-SUFFIX,ir.mail.126.com,🍃 应用净化
  - DOMAIN-SUFFIX,ir.mail.yeah.net,🍃 应用净化
  - DOMAIN-SUFFIX,mimg.126.net,🍃 应用净化
  - DOMAIN-SUFFIX,nc004x.corp.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,nc045x.corp.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,nex.corp.163.com,🍃 应用净化
  - DOMAIN-SUFFIX,oimagea2.ydstatic.com,🍃 应用净化
  - DOMAIN-SUFFIX,pagechoice.net,🍃 应用净化
  - DOMAIN-SUFFIX,prom.gome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,qchannel0d.cn,🍃 应用净化
  - DOMAIN-SUFFIX,qt002x.corp.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,rlogs.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,static.flv.uuzuonline.com,🍃 应用净化
  - DOMAIN-SUFFIX,tb060x.corp.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,tb104x.corp.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,union.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,wanproxy.127.net,🍃 应用净化
  - DOMAIN-SUFFIX,ydpushserver.youdao.com,🍃 应用净化
  - DOMAIN-SUFFIX,cvda.17173.com,🍃 应用净化
  - DOMAIN-SUFFIX,imgapp.yeyou.com,🍃 应用净化
  - DOMAIN-SUFFIX,log1.17173.com,🍃 应用净化
  - DOMAIN-SUFFIX,s.17173cdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,ue.yeyoucdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,vda.17173.com,🍃 应用净化
  - DOMAIN-SUFFIX,analytics.wanmei.com,🍃 应用净化
  - DOMAIN-SUFFIX,gg.stargame.com,🍃 应用净化
  - DOMAIN-SUFFIX,dl.2345.cn,🍃 应用净化
  - DOMAIN-SUFFIX,download.2345.cn,🍃 应用净化
  - DOMAIN-SUFFIX,houtai.2345.cn,🍃 应用净化
  - DOMAIN-SUFFIX,jifen.2345.cn,🍃 应用净化
  - DOMAIN-SUFFIX,jifendownload.2345.cn,🍃 应用净化
  - DOMAIN-SUFFIX,minipage.2345.cn,🍃 应用净化
  - DOMAIN-SUFFIX,wan.2345.cn,🍃 应用净化
  - DOMAIN-SUFFIX,zhushou.2345.cn,🍃 应用净化
  - DOMAIN-SUFFIX,3600.com,🍃 应用净化
  - DOMAIN-SUFFIX,gamebox.360.cn,🍃 应用净化
  - DOMAIN-SUFFIX,jiagu.360.cn,🍃 应用净化
  - DOMAIN-SUFFIX,kuaikan.netmon.360safe.com,🍃 应用净化
  - DOMAIN-SUFFIX,leak.360.cn,🍃 应用净化
  - DOMAIN-SUFFIX,lianmeng.360.cn,🍃 应用净化
  - DOMAIN-SUFFIX,pub.se.360.cn,🍃 应用净化
  - DOMAIN-SUFFIX,s.so.360.cn,🍃 应用净化
  - DOMAIN-SUFFIX,shouji.360.cn,🍃 应用净化
  - DOMAIN-SUFFIX,soft.data.weather.360.cn,🍃 应用净化
  - DOMAIN-SUFFIX,stat.360safe.com,🍃 应用净化
  - DOMAIN-SUFFIX,stat.m.360.cn,🍃 应用净化
  - DOMAIN-SUFFIX,update.360safe.com,🍃 应用净化
  - DOMAIN-SUFFIX,wan.360.cn,🍃 应用净化
  - DOMAIN-SUFFIX,58.xgo.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,brandshow.58.com,🍃 应用净化
  - DOMAIN-SUFFIX,imp.xgo.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,jing.58.com,🍃 应用净化
  - DOMAIN-SUFFIX,stat.xgo.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,track.58.com,🍃 应用净化
  - DOMAIN-SUFFIX,tracklog.58.com,🍃 应用净化
  - DOMAIN-SUFFIX,acjs.aliyun.com,🍃 应用净化
  - DOMAIN-SUFFIX,adash-c.m.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,adash-c.ut.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,adashx4yt.m.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,adashxgc.ut.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,afp.alicdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,ai.m.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,alipaylog.com,🍃 应用净化
  - DOMAIN-SUFFIX,atanx.alicdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,atanx2.alicdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,fav.simba.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,g.click.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,g.tbcdn.cn,🍃 应用净化
  - DOMAIN-SUFFIX,gma.alicdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,gtmsdd.alicdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,hydra.alibaba.com,🍃 应用净化
  - DOMAIN-SUFFIX,m.simba.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,pindao.huoban.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,re.m.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,redirect.simba.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,rj.m.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,sdkinit.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,show.re.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,simaba.m.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,simaba.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,srd.simba.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,strip.taobaocdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,tns.simba.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,tyh.taobao.com,🍃 应用净化
  - DOMAIN-SUFFIX,userimg.qunar.com,🍃 应用净化
  - DOMAIN-SUFFIX,yiliao.hupan.com,🍃 应用净化
  - DOMAIN-SUFFIX,3dns-2.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,3dns-3.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,activate-sea.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,activate-sjc0.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,activate.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,adobe-dns-2.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,adobe-dns-3.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,adobe-dns.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,ereg.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,geo2.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,hl2rcv.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,hlrcv.stage.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,lm.licenses.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,lmlicenses.wip4.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,na1r.services.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,na2m-pr.licenses.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,practivate.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,wip3.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,wwis-dubc1-vip60.adobe.com,🍃 应用净化
  - DOMAIN-SUFFIX,adserver.unityads.unity3d.com,🍃 应用净化
  - DOMAIN-SUFFIX,33.autohome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,adproxy.autohome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,al.autohome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,alert.autohome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,applogapi.autohome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,c.autohome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,cmx.autohome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,dspmnt.autohome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,pcd.autohome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,push.app.autohome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,pvx.autohome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,rd.autohome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,rdx.autohome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,stats.autohome.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,a.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,a.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.duapps.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.player.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,adm.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,adm.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,adscdn.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,adscdn.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,adx.xiaodutv.com,🍃 应用净化
  - DOMAIN-SUFFIX,ae.bdstatic.com,🍃 应用净化
  - DOMAIN-SUFFIX,afd.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,afd.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,als.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,als.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,anquan.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,anquan.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,antivirus.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,api.mobula.sdk.duapps.com,🍃 应用净化
  - DOMAIN-SUFFIX,appc.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,appc.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,as.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,as.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,baichuan.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,baidu9635.com,🍃 应用净化
  - DOMAIN-SUFFIX,baidustatic.com,🍃 应用净化
  - DOMAIN-SUFFIX,baidutv.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,banlv.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,bar.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,bdplus.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,btlaunch.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,c.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,c.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,cb.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,cb.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,cbjs.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,cbjs.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,cbjslog.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,cbjslog.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,cjhq.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,cjhq.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,cleaner.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,click.bes.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,click.hm.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,click.qianqian.com,🍃 应用净化
  - DOMAIN-SUFFIX,cm.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,cpro.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,cpro.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,cpro.baidustatic.com,🍃 应用净化
  - DOMAIN-SUFFIX,cpro.tieba.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,cpro.zhidao.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,cpro2.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,cpro2.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,cpu-admin.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,crs.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,crs.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,datax.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,dl-vip.bav.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,dl-vip.pcfaster.baidu.co.th,🍃 应用净化
  - DOMAIN-SUFFIX,dl.client.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,dl.ops.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,dl1sw.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,dl2.bav.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,dlsw.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,dlsw.br.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,download.bav.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,download.sd.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,drmcmm.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,drmcmm.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,dup.baidustatic.com,🍃 应用净化
  - DOMAIN-SUFFIX,dxp.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,dzl.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,e.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,e.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,eclick.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,eclick.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,ecma.bdimg.com,🍃 应用净化
  - DOMAIN-SUFFIX,ecmb.bdimg.com,🍃 应用净化
  - DOMAIN-SUFFIX,ecmc.bdimg.com,🍃 应用净化
  - DOMAIN-SUFFIX,eiv.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,eiv.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,em.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,ers.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,f10.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,fc-.cdn.bcebos.com,🍃 应用净化
  - DOMAIN-SUFFIX,fc-feed.cdn.bcebos.com,🍃 应用净化
  - DOMAIN-SUFFIX,fclick.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,fexclick.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,g.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,gimg.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,guanjia.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,hc.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,hc.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,hm.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,hm.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,hmma.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,hmma.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,hpd.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,hpd.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,idm-su.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,iebar.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,ikcode.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,imageplus.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,imageplus.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,img.taotaosou.cn,🍃 应用净化
  - DOMAIN-SUFFIX,img01.taotaosou.cn,🍃 应用净化
  - DOMAIN-SUFFIX,itsdata.map.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,j.br.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,kstj.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,log.music.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,log.nuomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,m1.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,ma.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,ma.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,mg09.zhaopin.com,🍃 应用净化
  - DOMAIN-SUFFIX,mipcache.bdstatic.com,🍃 应用净化
  - DOMAIN-SUFFIX,mobads-logs.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,mobads-logs.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,mobads.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,mobads.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,mpro.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,mtj.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,mtj.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,neirong.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,nsclick.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,nsclick.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,nsclickvideo.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,openrcv.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,pc.videoclick.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,pos.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,pups.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,pups.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,pups.bdimg.com,🍃 应用净化
  - DOMAIN-SUFFIX,push.music.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,push.zhanzhang.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,qchannel0d.cn,🍃 应用净化
  - DOMAIN-SUFFIX,qianclick.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,release.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,res.limei.com,🍃 应用净化
  - DOMAIN-SUFFIX,res.mi.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,rigel.baidustatic.com,🍃 应用净化
  - DOMAIN-SUFFIX,river.zhidao.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,rj.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,rj.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,rp.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,rp.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,rplog.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,s.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,sclick.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,sestat.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,shadu.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,share.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,sobar.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,sobartop.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,spcode.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,spcode.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,stat.v.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,su.bdimg.com,🍃 应用净化
  - DOMAIN-SUFFIX,su.bdstatic.com,🍃 应用净化
  - DOMAIN-SUFFIX,tk.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,tk.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,tkweb.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,tob-cms.bj.bcebos.com,🍃 应用净化
  - DOMAIN-SUFFIX,toolbar.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,tracker.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,tuijian.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,tuisong.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,tuisong.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,ubmcmm.baidustatic.com,🍃 应用净化
  - DOMAIN-SUFFIX,ucstat.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,ucstat.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,ulic.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,ulog.imap.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,union.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,union.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,unionimage.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,utility.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,utility.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,utk.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,utk.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,videopush.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,videopush.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,vv84.bj.bcebos.com,🍃 应用净化
  - DOMAIN-SUFFIX,w.gdown.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,w.x.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,wangmeng.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,wangmeng.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,weishi.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,wenku-cms.bj.bcebos.com,🍃 应用净化
  - DOMAIN-SUFFIX,wisepush.video.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,wm.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,wm.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,znsv.baidu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,znsv.baidu.com,🍃 应用净化
  - DOMAIN-SUFFIX,zz.bdstatic.com,🍃 应用净化
  - DOMAIN-SUFFIX,zzy1.quyaoya.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.zhangyue.com,🍃 应用净化
  - DOMAIN-SUFFIX,adm.ps.easou.com,🍃 应用净化
  - DOMAIN-SUFFIX,aishowbger.com,🍃 应用净化
  - DOMAIN-SUFFIX,api.itaoxiaoshuo.com,🍃 应用净化
  - DOMAIN-SUFFIX,assets.ps.easou.com,🍃 应用净化
  - DOMAIN-SUFFIX,bbcoe.cn,🍃 应用净化
  - DOMAIN-SUFFIX,cj.qidian.com,🍃 应用净化
  - DOMAIN-SUFFIX,dkeyn.com,🍃 应用净化
  - DOMAIN-SUFFIX,drdwy.com,🍃 应用净化
  - DOMAIN-SUFFIX,e.aa985.cn,🍃 应用净化
  - DOMAIN-SUFFIX,e.v02u9.cn,🍃 应用净化
  - DOMAIN-SUFFIX,e701.net,🍃 应用净化
  - DOMAIN-SUFFIX,ehxyz.com,🍃 应用净化
  - DOMAIN-SUFFIX,ethod.gzgmjcx.com,🍃 应用净化
  - DOMAIN-SUFFIX,focuscat.com,🍃 应用净化
  - DOMAIN-SUFFIX,game.qidian.com,🍃 应用净化
  - DOMAIN-SUFFIX,hdswgc.com,🍃 应用净化
  - DOMAIN-SUFFIX,jyd.fjzdmy.com,🍃 应用净化
  - DOMAIN-SUFFIX,m.ourlj.com,🍃 应用净化
  - DOMAIN-SUFFIX,m.txtxr.com,🍃 应用净化
  - DOMAIN-SUFFIX,m.vsxet.com,🍃 应用净化
  - DOMAIN-SUFFIX,miam4.cn,🍃 应用净化
  - DOMAIN-SUFFIX,o.if.qidian.com,🍃 应用净化
  - DOMAIN-SUFFIX,p.vq6nsu.cn,🍃 应用净化
  - DOMAIN-SUFFIX,picture.duokan.com,🍃 应用净化
  - DOMAIN-SUFFIX,push.zhangyue.com,🍃 应用净化
  - DOMAIN-SUFFIX,pyerc.com,🍃 应用净化
  - DOMAIN-SUFFIX,s1.cmfu.com,🍃 应用净化
  - DOMAIN-SUFFIX,sc.shayugg.com,🍃 应用净化
  - DOMAIN-SUFFIX,sdk.cferw.com,🍃 应用净化
  - DOMAIN-SUFFIX,sezvc.com,🍃 应用净化
  - DOMAIN-SUFFIX,sys.zhangyue.com,🍃 应用净化
  - DOMAIN-SUFFIX,tjlog.ps.easou.com,🍃 应用净化
  - DOMAIN-SUFFIX,tongji.qidian.com,🍃 应用净化
  - DOMAIN-SUFFIX,ut2.shuqistat.com,🍃 应用净化
  - DOMAIN-SUFFIX,xgcsr.com,🍃 应用净化
  - DOMAIN-SUFFIX,xjq.jxmqkj.com,🍃 应用净化
  - DOMAIN-SUFFIX,xpe.cxaerp.com,🍃 应用净化
  - DOMAIN-SUFFIX,xtzxmy.com,🍃 应用净化
  - DOMAIN-SUFFIX,xyrkl.com,🍃 应用净化
  - DOMAIN-SUFFIX,zhuanfakong.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.toutiao.com,🍃 应用净化
  - DOMAIN-SUFFIX,dsp.toutiao.com,🍃 应用净化
  - DOMAIN-SUFFIX,ic.snssdk.com,🍃 应用净化
  - DOMAIN-SUFFIX,log.snssdk.com,🍃 应用净化
  - DOMAIN-SUFFIX,nativeapp.toutiao.com,🍃 应用净化
  - DOMAIN-SUFFIX,pangolin-sdk-toutiao-b.com,🍃 应用净化
  - DOMAIN-SUFFIX,pangolin-sdk-toutiao.com,🍃 应用净化
  - DOMAIN-SUFFIX,pangolin.snssdk.com,🍃 应用净化
  - DOMAIN-SUFFIX,partner.toutiao.com,🍃 应用净化
  - DOMAIN-SUFFIX,pglstatp-toutiao.com,🍃 应用净化
  - DOMAIN-SUFFIX,sm.toutiao.com,🍃 应用净化
  - DOMAIN-SUFFIX,a.dangdang.com,🍃 应用净化
  - DOMAIN-SUFFIX,click.dangdang.com,🍃 应用净化
  - DOMAIN-SUFFIX,schprompt.dangdang.com,🍃 应用净化
  - DOMAIN-SUFFIX,t.dangdang.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.duomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,boxshows.com,🍃 应用净化
  - DOMAIN-SUFFIX,staticxx.facebook.com,🍃 应用净化
  - DOMAIN-SUFFIX,click1n.soufun.com,🍃 应用净化
  - DOMAIN-SUFFIX,clickm.fang.com,🍃 应用净化
  - DOMAIN-SUFFIX,clickn.fang.com,🍃 应用净化
  - DOMAIN-SUFFIX,countpvn.light.fang.com,🍃 应用净化
  - DOMAIN-SUFFIX,countubn.light.soufun.com,🍃 应用净化
  - DOMAIN-SUFFIX,mshow.fang.com,🍃 应用净化
  - DOMAIN-SUFFIX,tongji.home.soufun.com,🍃 应用净化
  - DOMAIN-SUFFIX,admob.com,🍃 应用净化
  - DOMAIN-SUFFIX,ads.gmodules.com,🍃 应用净化
  - DOMAIN-SUFFIX,ads.google.com,🍃 应用净化
  - DOMAIN-SUFFIX,adservice.google.com,🍃 应用净化
  - DOMAIN-SUFFIX,afd.l.google.com,🍃 应用净化
  - DOMAIN-SUFFIX,badad.googleplex.com,🍃 应用净化
  - DOMAIN-SUFFIX,csi.gstatic.com,🍃 应用净化
  - DOMAIN-SUFFIX,doubleclick.com,🍃 应用净化
  - DOMAIN-SUFFIX,doubleclick.net,🍃 应用净化
  - DOMAIN-SUFFIX,google-analytics.com,🍃 应用净化
  - DOMAIN-SUFFIX,googleadservices.com,🍃 应用净化
  - DOMAIN-SUFFIX,googleadsserving.cn,🍃 应用净化
  - DOMAIN-SUFFIX,googlecommerce.com,🍃 应用净化
  - DOMAIN-SUFFIX,googlesyndication.com,🍃 应用净化
  - DOMAIN-SUFFIX,mobileads.google.com,🍃 应用净化
  - DOMAIN-SUFFIX,pagead-tpc.l.google.com,🍃 应用净化
  - DOMAIN-SUFFIX,pagead.google.com,🍃 应用净化
  - DOMAIN-SUFFIX,pagead.l.google.com,🍃 应用净化
  - DOMAIN-SUFFIX,service.urchin.com,🍃 应用净化
  - DOMAIN-SUFFIX,ads.union.jd.com,🍃 应用净化
  - DOMAIN-SUFFIX,c-nfa.jd.com,🍃 应用净化
  - DOMAIN-SUFFIX,cps.360buy.com,🍃 应用净化
  - DOMAIN-SUFFIX,img-x.jd.com,🍃 应用净化
  - DOMAIN-SUFFIX,jrclick.jd.com,🍃 应用净化
  - DOMAIN-SUFFIX,jzt.jd.com,🍃 应用净化
  - DOMAIN-SUFFIX,policy.jd.com,🍃 应用净化
  - DOMAIN-SUFFIX,stat.m.jd.com,🍃 应用净化
  - DOMAIN-SUFFIX,ads.service.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,adsfile.bssdlbig.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,d.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,downmobile.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,gad.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,game.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,gamebox.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,gcapi.sy.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,gg.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,install.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,install2.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,kgmobilestat.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,kuaikaiapp.com,🍃 应用净化
  - DOMAIN-SUFFIX,log.stat.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,log.web.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,minidcsc.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,mo.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,mobilelog.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,msg.mobile.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,mvads.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,p.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,push.mobile.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,rtmonitor.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,sdn.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,tj.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,update.mobile.kugou.com,🍃 应用净化
  - DOMAIN-SUFFIX,apk.shouji.koowo.com,🍃 应用净化
  - DOMAIN-SUFFIX,deliver.kuwo.cn,🍃 应用净化
  - DOMAIN-SUFFIX,g.koowo.com,🍃 应用净化
  - DOMAIN-SUFFIX,g.kuwo.cn,🍃 应用净化
  - DOMAIN-SUFFIX,kwmsg.kuwo.cn,🍃 应用净化
  - DOMAIN-SUFFIX,log.kuwo.cn,🍃 应用净化
  - DOMAIN-SUFFIX,mobilead.kuwo.cn,🍃 应用净化
  - DOMAIN-SUFFIX,msclick2.kuwo.cn,🍃 应用净化
  - DOMAIN-SUFFIX,msphoneclick.kuwo.cn,🍃 应用净化
  - DOMAIN-SUFFIX,updatepage.kuwo.cn,🍃 应用净化
  - DOMAIN-SUFFIX,wa.kuwo.cn,🍃 应用净化
  - DOMAIN-SUFFIX,webstat.kuwo.cn,🍃 应用净化
  - DOMAIN-SUFFIX,aider-res.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,api-flow.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,api-game.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,api-push.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,aries.mzres.com,🍃 应用净化
  - DOMAIN-SUFFIX,bro.flyme.cn,🍃 应用净化
  - DOMAIN-SUFFIX,cal.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,ebook.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,ebook.res.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,game-res.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,game.res.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,infocenter.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,openapi-news.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,push.res.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,reader.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,reader.res.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,t-e.flyme.cn,🍃 应用净化
  - DOMAIN-SUFFIX,t-flow.flyme.cn,🍃 应用净化
  - DOMAIN-SUFFIX,tongji-res1.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,tongji.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,umid.orion.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,upush.res.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,uxip.meizu.com,🍃 应用净化
  - DOMAIN-SUFFIX,a.koudai.com,🍃 应用净化
  - DOMAIN-SUFFIX,adui.tg.meitu.com,🍃 应用净化
  - DOMAIN-SUFFIX,corp.meitu.com,🍃 应用净化
  - DOMAIN-SUFFIX,dc.meitustat.com,🍃 应用净化
  - DOMAIN-SUFFIX,gg.meitu.com,🍃 应用净化
  - DOMAIN-SUFFIX,mdc.meitustat.com,🍃 应用净化
  - DOMAIN-SUFFIX,meitubeauty.meitudata.com,🍃 应用净化
  - DOMAIN-SUFFIX,message.meitu.com,🍃 应用净化
  - DOMAIN-SUFFIX,rabbit.meitustat.com,🍃 应用净化
  - DOMAIN-SUFFIX,rabbit.tg.meitu.com,🍃 应用净化
  - DOMAIN-SUFFIX,tuiguang.meitu.com,🍃 应用净化
  - DOMAIN-SUFFIX,xiuxiu.android.dl.meitu.com,🍃 应用净化
  - DOMAIN-SUFFIX,xiuxiu.mobile.meitudata.com,🍃 应用净化
  - DOMAIN-SUFFIX,a.market.xiaomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.xiaomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad1.xiaomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,adv.sec.intl.miui.com,🍃 应用净化
  - DOMAIN-SUFFIX,adv.sec.miui.com,🍃 应用净化
  - DOMAIN-SUFFIX,bss.pandora.xiaomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,d.g.mi.com,🍃 应用净化
  - DOMAIN-SUFFIX,data.mistat.xiaomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,de.pandora.xiaomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,dvb.pandora.xiaomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,jellyfish.pandora.xiaomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,migc.g.mi.com,🍃 应用净化
  - DOMAIN-SUFFIX,migcreport.g.mi.com,🍃 应用净化
  - DOMAIN-SUFFIX,notice.game.xiaomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,ppurifier.game.xiaomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,r.browser.miui.com,🍃 应用净化
  - DOMAIN-SUFFIX,security.browser.miui.com,🍃 应用净化
  - DOMAIN-SUFFIX,shenghuo.xiaomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,stat.pandora.xiaomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,union.mi.com,🍃 应用净化
  - DOMAIN-SUFFIX,wtradv.market.xiaomi.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.api.moji.com,🍃 应用净化
  - DOMAIN-SUFFIX,app.moji001.com,🍃 应用净化
  - DOMAIN-SUFFIX,cdn.moji002.com,🍃 应用净化
  - DOMAIN-SUFFIX,cdn2.moji002.com,🍃 应用净化
  - DOMAIN-SUFFIX,fds.api.moji.com,🍃 应用净化
  - DOMAIN-SUFFIX,log.moji.com,🍃 应用净化
  - DOMAIN-SUFFIX,stat.moji.com,🍃 应用净化
  - DOMAIN-SUFFIX,ugc.moji001.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.qingting.fm,🍃 应用净化
  - DOMAIN-SUFFIX,admgr.qingting.fm,🍃 应用净化
  - DOMAIN-SUFFIX,dload.qd.qingting.fm,🍃 应用净化
  - DOMAIN-SUFFIX,logger.qingting.fm,🍃 应用净化
  - DOMAIN-SUFFIX,s.qd.qingting.fm,🍃 应用净化
  - DOMAIN-SUFFIX,s.qd.qingtingfm.com,🍃 应用净化
  - DOMAIN-KEYWORD,omgmtaw,🍃 应用净化
  - DOMAIN,adsmind.apdcdn.tc.qq.com,🍃 应用净化
  - DOMAIN,adsmind.gdtimg.com,🍃 应用净化
  - DOMAIN,adsmind.tc.qq.com,🍃 应用净化
  - DOMAIN,pgdt.gtimg.cn,🍃 应用净化
  - DOMAIN,pgdt.gtimg.com,🍃 应用净化
  - DOMAIN,pgdt.ugdtimg.com,🍃 应用净化
  - DOMAIN,splashqqlive.gtimg.com,🍃 应用净化
  - DOMAIN,wa.gtimg.com,🍃 应用净化
  - DOMAIN,wxsnsdy.wxs.qq.com,🍃 应用净化
  - DOMAIN,wxsnsdythumb.wxs.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,act.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.qun.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,adsfile.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,bugly.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,buluo.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,e.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,gdt.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,l.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,monitor.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,pingma.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,pingtcss.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,report.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,tajs.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,tcss.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,uu.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,ebp.renren.com,🍃 应用净化
  - DOMAIN-SUFFIX,jebe.renren.com,🍃 应用净化
  - DOMAIN-SUFFIX,jebe.xnimg.cn,🍃 应用净化
  - DOMAIN-SUFFIX,ad.sina.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,adbox.sina.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,add.sina.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,adimg.mobile.sina.cn,🍃 应用净化
  - DOMAIN-SUFFIX,adm.sina.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,alitui.weibo.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,biz.weibo.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,cre.dp.sina.cn,🍃 应用净化
  - DOMAIN-SUFFIX,dcads.sina.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,dd.sina.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,dmp.sina.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,game.weibo.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,gw5.push.mcp.weibo.cn,🍃 应用净化
  - DOMAIN-SUFFIX,leju.sina.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,log.mix.sina.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,mobileads.dx.cn,🍃 应用净化
  - DOMAIN-SUFFIX,newspush.sinajs.cn,🍃 应用净化
  - DOMAIN-SUFFIX,pay.mobile.sina.cn,🍃 应用净化
  - DOMAIN-SUFFIX,sax.mobile.sina.cn,🍃 应用净化
  - DOMAIN-SUFFIX,sax.sina.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,saxd.sina.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,sdkapp.mobile.sina.cn,🍃 应用净化
  - DOMAIN-SUFFIX,sdkapp.uve.weibo.com,🍃 应用净化
  - DOMAIN-SUFFIX,sdkclick.mobile.sina.cn,🍃 应用净化
  - DOMAIN-SUFFIX,slog.sina.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,trends.mobile.sina.cn,🍃 应用净化
  - DOMAIN-SUFFIX,tui.weibo.com,🍃 应用净化
  - DOMAIN-SUFFIX,u1.img.mobile.sina.cn,🍃 应用净化
  - DOMAIN-SUFFIX,wax.weibo.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,wbapp.mobile.sina.cn,🍃 应用净化
  - DOMAIN-SUFFIX,wbapp.uve.weibo.com,🍃 应用净化
  - DOMAIN-SUFFIX,wbclick.mobile.sina.cn,🍃 应用净化
  - DOMAIN-SUFFIX,wbpctips.mobile.sina.cn,🍃 应用净化
  - DOMAIN-SUFFIX,zymo.mps.weibo.com,🍃 应用净化
  - DOMAIN-SUFFIX,123.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,123.sogoucdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,adsence.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,amfi.gou.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,brand.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,cpc.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,epro.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,fair.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,files2.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,galaxy.sogoucdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,golden1.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,goto.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,inte.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,iwan.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,lu.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,lu.sogoucdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,pb.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,pd.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,pv.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,theta.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,wan.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,wangmeng.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,applovin.com,🍃 应用净化
  - DOMAIN-SUFFIX,guangzhuiyuan.com,🍃 应用净化
  - DOMAIN-SUFFIX,ads-twitter.com,🍃 应用净化
  - DOMAIN-SUFFIX,ads.twitter.com,🍃 应用净化
  - DOMAIN-SUFFIX,analytics.twitter.com,🍃 应用净化
  - DOMAIN-SUFFIX,p.twitter.com,🍃 应用净化
  - DOMAIN-SUFFIX,scribe.twitter.com,🍃 应用净化
  - DOMAIN-SUFFIX,syndication-o.twitter.com,🍃 应用净化
  - DOMAIN-SUFFIX,syndication.twitter.com,🍃 应用净化
  - DOMAIN-SUFFIX,tellapart.com,🍃 应用净化
  - DOMAIN-SUFFIX,urls.api.twitter.com,🍃 应用净化
  - DOMAIN-SUFFIX,adslot.uc.cn,🍃 应用净化
  - DOMAIN-SUFFIX,api.mp.uc.cn,🍃 应用净化
  - DOMAIN-SUFFIX,applog.uc.cn,🍃 应用净化
  - DOMAIN-SUFFIX,client.video.ucweb.com,🍃 应用净化
  - DOMAIN-SUFFIX,cms.ucweb.com,🍃 应用净化
  - DOMAIN-SUFFIX,dispatcher.upmc.uc.cn,🍃 应用净化
  - DOMAIN-SUFFIX,huichuan.sm.cn,🍃 应用净化
  - DOMAIN-SUFFIX,log.cs.pp.cn,🍃 应用净化
  - DOMAIN-SUFFIX,m.uczzd.cn,🍃 应用净化
  - DOMAIN-SUFFIX,patriot.cs.pp.cn,🍃 应用净化
  - DOMAIN-SUFFIX,puds.ucweb.com,🍃 应用净化
  - DOMAIN-SUFFIX,server.m.pp.cn,🍃 应用净化
  - DOMAIN-SUFFIX,track.uc.cn,🍃 应用净化
  - DOMAIN-SUFFIX,u.uc123.com,🍃 应用净化
  - DOMAIN-SUFFIX,u.ucfly.com,🍃 应用净化
  - DOMAIN-SUFFIX,uc.ucweb.com,🍃 应用净化
  - DOMAIN-SUFFIX,ucsec.ucweb.com,🍃 应用净化
  - DOMAIN-SUFFIX,ucsec1.ucweb.com,🍃 应用净化
  - DOMAIN-SUFFIX,aoodoo.feng.com,🍃 应用净化
  - DOMAIN-SUFFIX,fengbuy.com,🍃 应用净化
  - DOMAIN-SUFFIX,push.feng.com,🍃 应用净化
  - DOMAIN-SUFFIX,we.tm,🍃 应用净化
  - DOMAIN-SUFFIX,yes1.feng.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.docer.wps.cn,🍃 应用净化
  - DOMAIN-SUFFIX,adm.zookingsoft.com,🍃 应用净化
  - DOMAIN-SUFFIX,bannera.kingsoft-office-service.com,🍃 应用净化
  - DOMAIN-SUFFIX,bole.shangshufang.ksosoft.com,🍃 应用净化
  - DOMAIN-SUFFIX,counter.kingsoft.com,🍃 应用净化
  - DOMAIN-SUFFIX,docerad.wps.cn,🍃 应用净化
  - DOMAIN-SUFFIX,gou.wps.cn,🍃 应用净化
  - DOMAIN-SUFFIX,hoplink.ksosoft.com,🍃 应用净化
  - DOMAIN-SUFFIX,ic.ksosoft.com,🍃 应用净化
  - DOMAIN-SUFFIX,img.gou.wpscdn.cn,🍃 应用净化
  - DOMAIN-SUFFIX,info.wps.cn,🍃 应用净化
  - DOMAIN-SUFFIX,ios-informationplatform.wps.cn,🍃 应用净化
  - DOMAIN-SUFFIX,minfo.wps.cn,🍃 应用净化
  - DOMAIN-SUFFIX,mo.res.wpscdn.cn,🍃 应用净化
  - DOMAIN-SUFFIX,news.docer.com,🍃 应用净化
  - DOMAIN-SUFFIX,notify.wps.cn,🍃 应用净化
  - DOMAIN-SUFFIX,pc.uf.ksosoft.com,🍃 应用净化
  - DOMAIN-SUFFIX,pcfg.wps.cn,🍃 应用净化
  - DOMAIN-SUFFIX,pixiu.shangshufang.ksosoft.com,🍃 应用净化
  - DOMAIN-SUFFIX,push.wps.cn,🍃 应用净化
  - DOMAIN-SUFFIX,rating6.kingsoft-office-service.com,🍃 应用净化
  - DOMAIN-SUFFIX,up.wps.kingsoft.com,🍃 应用净化
  - DOMAIN-SUFFIX,wpsweb-dc.wps.cn,🍃 应用净化
  - DOMAIN-SUFFIX,c.51y5.net,🍃 应用净化
  - DOMAIN-SUFFIX,cdsget.51y5.net,🍃 应用净化
  - DOMAIN-SUFFIX,news-imgpb.51y5.net,🍃 应用净化
  - DOMAIN-SUFFIX,wifiapidd.51y5.net,🍃 应用净化
  - DOMAIN-SUFFIX,wkanc.51y5.net,🍃 应用净化
  - DOMAIN-SUFFIX,adse.ximalaya.com,🍃 应用净化
  - DOMAIN-SUFFIX,linkeye.ximalaya.com,🍃 应用净化
  - DOMAIN-SUFFIX,location.ximalaya.com,🍃 应用净化
  - DOMAIN-SUFFIX,xdcs-collector.ximalaya.com,🍃 应用净化
  - DOMAIN-SUFFIX,biz5.kankan.com,🍃 应用净化
  - DOMAIN-SUFFIX,float.kankan.com,🍃 应用净化
  - DOMAIN-SUFFIX,hub5btmain.sandai.net,🍃 应用净化
  - DOMAIN-SUFFIX,hub5emu.sandai.net,🍃 应用净化
  - DOMAIN-SUFFIX,logic.cpm.cm.kankan.com,🍃 应用净化
  - DOMAIN-SUFFIX,upgrade.xl9.xunlei.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.wretch.cc,🍃 应用净化
  - DOMAIN-SUFFIX,ads.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,adserver.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,adss.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,analytics.query.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,analytics.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,ane.yahoo.co.jp,🍃 应用净化
  - DOMAIN-SUFFIX,ard.yahoo.co.jp,🍃 应用净化
  - DOMAIN-SUFFIX,beap-bc.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,clicks.beap.bc.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,comet.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,doubleplay-conf-yql.media.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,flurry.com,🍃 应用净化
  - DOMAIN-SUFFIX,gemini.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,geo.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,js-apac-ss.ysm.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,locdrop.query.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,onepush.query.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,p3p.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,partnerads.ysm.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,ws.progrss.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,yads.yahoo.co.jp,🍃 应用净化
  - DOMAIN-SUFFIX,ybp.yahoo.com,🍃 应用净化
  - DOMAIN-SUFFIX,shrek.6.cn,🍃 应用净化
  - DOMAIN-SUFFIX,simba.6.cn,🍃 应用净化
  - DOMAIN-SUFFIX,union.6.cn,🍃 应用净化
  - DOMAIN-SUFFIX,logger.baofeng.com,🍃 应用净化
  - DOMAIN-SUFFIX,xs.houyi.baofeng.net,🍃 应用净化
  - DOMAIN-SUFFIX,dotcounter.douyutv.com,🍃 应用净化
  - DOMAIN-SUFFIX,api.newad.ifeng.com,🍃 应用净化
  - DOMAIN-SUFFIX,exp.3g.ifeng.com,🍃 应用净化
  - DOMAIN-SUFFIX,game.ifeng.com,🍃 应用净化
  - DOMAIN-SUFFIX,iis3g.deliver.ifeng.com,🍃 应用净化
  - DOMAIN-SUFFIX,mfp.deliver.ifeng.com,🍃 应用净化
  - DOMAIN-SUFFIX,stadig.ifeng.com,🍃 应用净化
  - DOMAIN-SUFFIX,adm.funshion.com,🍃 应用净化
  - DOMAIN-SUFFIX,jobsfe.funshion.com,🍃 应用净化
  - DOMAIN-SUFFIX,po.funshion.com,🍃 应用净化
  - DOMAIN-SUFFIX,pub.funshion.com,🍃 应用净化
  - DOMAIN-SUFFIX,pv.funshion.com,🍃 应用净化
  - DOMAIN-SUFFIX,stat.funshion.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.m.iqiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,afp.iqiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,c.uaa.iqiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,cloudpush.iqiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,cm.passport.iqiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,cupid.iqiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,emoticon.sns.iqiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,gamecenter.iqiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,ifacelog.iqiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,mbdlog.iqiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,meta.video.qiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,msg.71.am,🍃 应用净化
  - DOMAIN-SUFFIX,msg1.video.qiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,msg2.video.qiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,paopao.iqiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,paopaod.qiyipic.com,🍃 应用净化
  - DOMAIN-SUFFIX,policy.video.iqiyi.com,🍃 应用净化
  - DOMAIN-SUFFIX,yuedu.iqiyi.com,🍃 应用净化
  - IP-CIDR,101.227.200.0/24,🍃 应用净化,no-resolve
  - IP-CIDR,101.227.200.11/32,🍃 应用净化,no-resolve
  - IP-CIDR,101.227.200.28/32,🍃 应用净化,no-resolve
  - IP-CIDR,101.227.97.240/32,🍃 应用净化,no-resolve
  - IP-CIDR,124.192.153.42/32,🍃 应用净化,no-resolve
  - DOMAIN-SUFFIX,gug.ku6cdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,pq.stat.ku6.com,🍃 应用净化
  - DOMAIN-SUFFIX,st.vq.ku6.cn,🍃 应用净化
  - DOMAIN-SUFFIX,static.ku6.com,🍃 应用净化
  - DOMAIN-SUFFIX,1.letvlive.com,🍃 应用净化
  - DOMAIN-SUFFIX,2.letvlive.com,🍃 应用净化
  - DOMAIN-SUFFIX,ark.letv.com,🍃 应用净化
  - DOMAIN-SUFFIX,dc.letv.com,🍃 应用净化
  - DOMAIN-SUFFIX,fz.letv.com,🍃 应用净化
  - DOMAIN-SUFFIX,g3.letv.com,🍃 应用净化
  - DOMAIN-SUFFIX,game.letvstore.com,🍃 应用净化
  - DOMAIN-SUFFIX,i0.letvimg.com,🍃 应用净化
  - DOMAIN-SUFFIX,i3.letvimg.com,🍃 应用净化
  - DOMAIN-SUFFIX,minisite.letv.com,🍃 应用净化
  - DOMAIN-SUFFIX,n.mark.letv.com,🍃 应用净化
  - DOMAIN-SUFFIX,pro.hoye.letv.com,🍃 应用净化
  - DOMAIN-SUFFIX,pro.letv.com,🍃 应用净化
  - DOMAIN-SUFFIX,stat.letv.com,🍃 应用净化
  - DOMAIN-SUFFIX,static.app.m.letv.com,🍃 应用净化
  - DOMAIN-SUFFIX,click.hunantv.com,🍃 应用净化
  - DOMAIN-SUFFIX,da.hunantv.com,🍃 应用净化
  - DOMAIN-SUFFIX,da.mgtv.com,🍃 应用净化
  - DOMAIN-SUFFIX,log.hunantv.com,🍃 应用净化
  - DOMAIN-SUFFIX,log.v2.hunantv.com,🍃 应用净化
  - DOMAIN-SUFFIX,p2.hunantv.com,🍃 应用净化
  - DOMAIN-SUFFIX,res.hunantv.com,🍃 应用净化
  - DOMAIN-SUFFIX,888.tv.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,adnet.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,ads.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,aty.hd.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,aty.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,bd.hd.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,click.hd.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,click2.hd.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,ctr.hd.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,epro.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,epro.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,go.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,golden1.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,golden1.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,hui.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,inte.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,inte.sogoucdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,inte.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,lm.tv.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,lu.sogoucdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,pb.hd.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,push.tv.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,pv.hd.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,pv.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,pv.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,theta.sogoucdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,um.hd.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,uranus.sogou.com,🍃 应用净化
  - DOMAIN-SUFFIX,uranus.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,wan.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,wl.hd.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,yule.sohu.com,🍃 应用净化
  - DOMAIN-SUFFIX,afp.pplive.com,🍃 应用净化
  - DOMAIN-SUFFIX,app.aplus.pptv.com,🍃 应用净化
  - DOMAIN-SUFFIX,as.aplus.pptv.com,🍃 应用净化
  - DOMAIN-SUFFIX,asimgs.pplive.cn,🍃 应用净化
  - DOMAIN-SUFFIX,de.as.pptv.com,🍃 应用净化
  - DOMAIN-SUFFIX,jp.as.pptv.com,🍃 应用净化
  - DOMAIN-SUFFIX,pp2.pptv.com,🍃 应用净化
  - DOMAIN-SUFFIX,stat.pptv.com,🍃 应用净化
  - DOMAIN-SUFFIX,btrace.video.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,c.l.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,dp3.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,livep.l.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,lives.l.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,livew.l.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,mcgi.v.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,mdevstat.qqlive.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,omgmta1.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,p.l.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,rcgi.video.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,t.l.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,u.l.qq.com,🍃 应用净化
  - DOMAIN-SUFFIX,a-dxk.play.api.3g.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,actives.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.api.3g.tudou.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.api.3g.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.api.mobile.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.mobile.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,adcontrol.tudou.com,🍃 应用净化
  - DOMAIN-SUFFIX,adplay.tudou.com,🍃 应用净化
  - DOMAIN-SUFFIX,b.smartvideo.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,c.yes.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,dev-push.m.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,dl.g.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,dmapp.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,e.stat.ykimg.com,🍃 应用净化
  - DOMAIN-SUFFIX,gamex.mobile.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,goods.tudou.com,🍃 应用净化
  - DOMAIN-SUFFIX,hudong.pl.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,hz.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,iwstat.tudou.com,🍃 应用净化
  - DOMAIN-SUFFIX,iyes.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,l.ykimg.com,🍃 应用净化
  - DOMAIN-SUFFIX,l.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,lstat.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,lvip.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,mobilemsg.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,msg.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,myes.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,nstat.tudou.com,🍃 应用净化
  - DOMAIN-SUFFIX,p-log.ykimg.com,🍃 应用净化
  - DOMAIN-SUFFIX,p.l.ykimg.com,🍃 应用净化
  - DOMAIN-SUFFIX,p.l.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,passport-log.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,push.m.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,r.l.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,s.p.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,sdk.m.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,stat.tudou.com,🍃 应用净化
  - DOMAIN-SUFFIX,stat.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,stats.tudou.com,🍃 应用净化
  - DOMAIN-SUFFIX,store.tv.api.3g.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,store.xl.api.3g.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,tdrec.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,test.ott.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,v.l.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,val.api.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,wan.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,ykatr.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,ykrec.youku.com,🍃 应用净化
  - DOMAIN-SUFFIX,ykrectab.youku.com,🍃 应用净化
  - IP-CIDR,117.177.248.17/32,🍃 应用净化,no-resolve
  - IP-CIDR,117.177.248.41/32,🍃 应用净化,no-resolve
  - IP-CIDR,223.87.176.139/32,🍃 应用净化,no-resolve
  - IP-CIDR,223.87.176.176/32,🍃 应用净化,no-resolve
  - IP-CIDR,223.87.177.180/32,🍃 应用净化,no-resolve
  - IP-CIDR,223.87.177.182/32,🍃 应用净化,no-resolve
  - IP-CIDR,223.87.177.184/32,🍃 应用净化,no-resolve
  - IP-CIDR,223.87.177.43/32,🍃 应用净化,no-resolve
  - IP-CIDR,223.87.177.47/32,🍃 应用净化,no-resolve
  - IP-CIDR,223.87.177.80/32,🍃 应用净化,no-resolve
  - IP-CIDR,223.87.182.101/32,🍃 应用净化,no-resolve
  - IP-CIDR,223.87.182.102/32,🍃 应用净化,no-resolve
  - IP-CIDR,223.87.182.11/32,🍃 应用净化,no-resolve
  - IP-CIDR,223.87.182.52/32,🍃 应用净化,no-resolve
  - DOMAIN-SUFFIX,azabu-u.ac.jp,🍃 应用净化
  - DOMAIN-SUFFIX,couchcoaster.jp,🍃 应用净化
  - DOMAIN-SUFFIX,delivery.dmkt-sp.jp,🍃 应用净化
  - DOMAIN-SUFFIX,ehg-youtube.hitbox.com,🍃 应用净化
  - DOMAIN-SUFFIX,nichibenren.or.jp,🍃 应用净化
  - DOMAIN-SUFFIX,nicorette.co.kr,🍃 应用净化
  - DOMAIN-SUFFIX,ssl-youtube.2cnt.net,🍃 应用净化
  - DOMAIN-SUFFIX,youtube.112.2o7.net,🍃 应用净化
  - DOMAIN-SUFFIX,youtube.2cnt.net,🍃 应用净化
  - DOMAIN-SUFFIX,acsystem.wasu.tv,🍃 应用净化
  - DOMAIN-SUFFIX,ads.cdn.tvb.com,🍃 应用净化
  - DOMAIN-SUFFIX,ads.wasu.tv,🍃 应用净化
  - DOMAIN-SUFFIX,afp.wasu.tv,🍃 应用净化
  - DOMAIN-SUFFIX,c.algovid.com,🍃 应用净化
  - DOMAIN-SUFFIX,gg.jtertp.com,🍃 应用净化
  - DOMAIN-SUFFIX,gridsum-vd.cntv.cn,🍃 应用净化
  - DOMAIN-SUFFIX,kwflvcdn.000dn.com,🍃 应用净化
  - DOMAIN-SUFFIX,logstat.t.sfht.com,🍃 应用净化
  - DOMAIN-SUFFIX,match.rtbidder.net,🍃 应用净化
  - DOMAIN-SUFFIX,n-st.vip.com,🍃 应用净化
  - DOMAIN-SUFFIX,pop.uusee.com,🍃 应用净化
  - DOMAIN-SUFFIX,static.duoshuo.com,🍃 应用净化
  - DOMAIN-SUFFIX,t.cr-nielsen.com,🍃 应用净化
  - DOMAIN-SUFFIX,terren.cntv.cn,🍃 应用净化
  - DOMAIN-SUFFIX,1.win7china.com,🍃 应用净化
  - DOMAIN-SUFFIX,168.it168.com,🍃 应用净化
  - DOMAIN-SUFFIX,2.win7china.com,🍃 应用净化
  - DOMAIN-SUFFIX,801.tianya.cn,🍃 应用净化
  - DOMAIN-SUFFIX,801.tianyaui.cn,🍃 应用净化
  - DOMAIN-SUFFIX,803.tianya.cn,🍃 应用净化
  - DOMAIN-SUFFIX,803.tianyaui.cn,🍃 应用净化
  - DOMAIN-SUFFIX,806.tianya.cn,🍃 应用净化
  - DOMAIN-SUFFIX,806.tianyaui.cn,🍃 应用净化
  - DOMAIN-SUFFIX,808.tianya.cn,🍃 应用净化
  - DOMAIN-SUFFIX,808.tianyaui.cn,🍃 应用净化
  - DOMAIN-SUFFIX,92x.tumblr.com,🍃 应用净化
  - DOMAIN-SUFFIX,a1.itc.cn,🍃 应用净化
  - DOMAIN-SUFFIX,ad-channel.wikawika.xyz,🍃 应用净化
  - DOMAIN-SUFFIX,ad-display.wikawika.xyz,🍃 应用净化
  - DOMAIN-SUFFIX,ad.12306.cn,🍃 应用净化
  - DOMAIN-SUFFIX,ad.3.cn,🍃 应用净化
  - DOMAIN-SUFFIX,ad.95306.cn,🍃 应用净化
  - DOMAIN-SUFFIX,ad.caiyunapp.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.cctv.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.cmvideo.cn,🍃 应用净化
  - DOMAIN-SUFFIX,ad.csdn.net,🍃 应用净化
  - DOMAIN-SUFFIX,ad.ganji.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.house365.com,🍃 应用净化
  - DOMAIN-SUFFIX,ad.thepaper.cn,🍃 应用净化
  - DOMAIN-SUFFIX,ad.unimhk.com,🍃 应用净化
  - DOMAIN-SUFFIX,adadmin.house365.com,🍃 应用净化
  - DOMAIN-SUFFIX,adhome.1fangchan.com,🍃 应用净化
  - DOMAIN-SUFFIX,adm.10jqka.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,ads.csdn.net,🍃 应用净化
  - DOMAIN-SUFFIX,ads.feedly.com,🍃 应用净化
  - DOMAIN-SUFFIX,ads.genieessp.com,🍃 应用净化
  - DOMAIN-SUFFIX,ads.house365.com,🍃 应用净化
  - DOMAIN-SUFFIX,ads.linkedin.com,🍃 应用净化
  - DOMAIN-SUFFIX,adshownew.it168.com,🍃 应用净化
  - DOMAIN-SUFFIX,adv.ccb.com,🍃 应用净化
  - DOMAIN-SUFFIX,advert.api.thejoyrun.com,🍃 应用净化
  - DOMAIN-SUFFIX,analytics.ganji.com,🍃 应用净化
  - DOMAIN-SUFFIX,api-deal.kechenggezi.com,🍃 应用净化
  - DOMAIN-SUFFIX,api-z.weidian.com,🍃 应用净化
  - DOMAIN-SUFFIX,app-monitor.ele.me,🍃 应用净化
  - DOMAIN-SUFFIX,bat.bing.com,🍃 应用净化
  - DOMAIN-SUFFIX,bd1.52che.com,🍃 应用净化
  - DOMAIN-SUFFIX,bd2.52che.com,🍃 应用净化
  - DOMAIN-SUFFIX,bdj.tianya.cn,🍃 应用净化
  - DOMAIN-SUFFIX,bdj.tianyaui.cn,🍃 应用净化
  - DOMAIN-SUFFIX,beacon.tingyun.com,🍃 应用净化
  - DOMAIN-SUFFIX,cdn.jiuzhilan.com,🍃 应用净化
  - DOMAIN-SUFFIX,click.cheshi-img.com,🍃 应用净化
  - DOMAIN-SUFFIX,click.cheshi.com,🍃 应用净化
  - DOMAIN-SUFFIX,click.ganji.com,🍃 应用净化
  - DOMAIN-SUFFIX,click.tianya.cn,🍃 应用净化
  - DOMAIN-SUFFIX,click.tianyaui.cn,🍃 应用净化
  - DOMAIN-SUFFIX,client-api.ele.me,🍃 应用净化
  - DOMAIN-SUFFIX,collector.githubapp.com,🍃 应用净化
  - DOMAIN-SUFFIX,counter.csdn.net,🍃 应用净化
  - DOMAIN-SUFFIX,d0.xcar.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,de.soquair.com,🍃 应用净化
  - DOMAIN-SUFFIX,dol.tianya.cn,🍃 应用净化
  - DOMAIN-SUFFIX,dol.tianyaui.cn,🍃 应用净化
  - DOMAIN-SUFFIX,dw.xcar.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,e.nexac.com,🍃 应用净化
  - DOMAIN-SUFFIX,eq.10jqka.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,exp.17wo.cn,🍃 应用净化
  - DOMAIN-SUFFIX,game.51yund.com,🍃 应用净化
  - DOMAIN-SUFFIX,ganjituiguang.ganji.com,🍃 应用净化
  - DOMAIN-SUFFIX,grand.ele.me,🍃 应用净化
  - DOMAIN-SUFFIX,hosting.miarroba.info,🍃 应用净化
  - DOMAIN-SUFFIX,iadsdk.apple.com,🍃 应用净化
  - DOMAIN-SUFFIX,image.gentags.com,🍃 应用净化
  - DOMAIN-SUFFIX,its-dori.tumblr.com,🍃 应用净化
  - DOMAIN-SUFFIX,log.outbrain.com,🍃 应用净化
  - DOMAIN-SUFFIX,m.12306media.com,🍃 应用净化
  - DOMAIN-SUFFIX,media.cheshi-img.com,🍃 应用净化
  - DOMAIN-SUFFIX,media.cheshi.com,🍃 应用净化
  - DOMAIN-SUFFIX,mobile-pubt.ele.me,🍃 应用净化
  - DOMAIN-SUFFIX,mobileads.msn.com,🍃 应用净化
  - DOMAIN-SUFFIX,n.cosbot.cn,🍃 应用净化
  - DOMAIN-SUFFIX,newton-api.ele.me,🍃 应用净化
  - DOMAIN-SUFFIX,ozone.10jqka.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,pdl.gionee.com,🍃 应用净化
  - DOMAIN-SUFFIX,pica-juicy.picacomic.com,🍃 应用净化
  - DOMAIN-SUFFIX,pixel.wp.com,🍃 应用净化
  - DOMAIN-SUFFIX,pub.mop.com,🍃 应用净化
  - DOMAIN-SUFFIX,push.wandoujia.com,🍃 应用净化
  - DOMAIN-SUFFIX,pv.cheshi-img.com,🍃 应用净化
  - DOMAIN-SUFFIX,pv.cheshi.com,🍃 应用净化
  - DOMAIN-SUFFIX,pv.xcar.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,qdp.qidian.com,🍃 应用净化
  - DOMAIN-SUFFIX,res.gwifi.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,ssp.kssws.ks-cdn.com,🍃 应用净化
  - DOMAIN-SUFFIX,sta.ganji.com,🍃 应用净化
  - DOMAIN-SUFFIX,stat.10jqka.com.cn,🍃 应用净化
  - DOMAIN-SUFFIX,stat.it168.com,🍃 应用净化
  - DOMAIN-SUFFIX,stats.chinaz.com,🍃 应用净化
  - DOMAIN-SUFFIX,stats.developingperspective.com,🍃 应用净化
  - DOMAIN-SUFFIX,track.hujiang.com,🍃 应用净化
  - DOMAIN-SUFFIX,tracker.yhd.com,🍃 应用净化
  - DOMAIN-SUFFIX,tralog.ganji.com,🍃 应用净化
  - DOMAIN-SUFFIX,up.qingdaonews.com,🍃 应用净化
  - DOMAIN-SUFFIX,vaserviece.10jqka.com.cn,🍃 应用净化
  - DOMAIN,alt1-mtalk.google.com,📢 谷歌FCM
  - DOMAIN,alt2-mtalk.google.com,📢 谷歌FCM
  - DOMAIN,alt3-mtalk.google.com,📢 谷歌FCM
  - DOMAIN,alt4-mtalk.google.com,📢 谷歌FCM
  - DOMAIN,alt5-mtalk.google.com,📢 谷歌FCM
  - DOMAIN,alt6-mtalk.google.com,📢 谷歌FCM
  - DOMAIN,alt7-mtalk.google.com,📢 谷歌FCM
  - DOMAIN,alt8-mtalk.google.com,📢 谷歌FCM
  - DOMAIN,mtalk.google.com,📢 谷歌FCM
  - IP-CIDR,64.233.177.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,64.233.186.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,64.233.187.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,64.233.188.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,64.233.189.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,74.125.23.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,74.125.24.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,74.125.28.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,74.125.127.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,74.125.137.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,74.125.203.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,74.125.204.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,74.125.206.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,108.177.125.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,142.250.4.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,142.250.10.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,142.250.31.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,142.250.96.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,172.217.194.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,172.217.218.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,172.217.219.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,172.253.63.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,172.253.122.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,173.194.175.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,173.194.218.188/32,📢 谷歌FCM,no-resolve
  - IP-CIDR,209.85.233.188/32,📢 谷歌FCM,no-resolve
  - DOMAIN-SUFFIX,265.com,🎯 全球直连
  - DOMAIN-SUFFIX,2mdn.net,🎯 全球直连
  - DOMAIN-SUFFIX,alt1-mtalk.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,alt2-mtalk.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,alt3-mtalk.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,alt4-mtalk.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,alt5-mtalk.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,alt6-mtalk.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,alt7-mtalk.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,alt8-mtalk.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,app-measurement.com,🎯 全球直连
  - DOMAIN-SUFFIX,cache.pack.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,clickserve.dartsearch.net,🎯 全球直连
  - DOMAIN-SUFFIX,crl.pki.goog,🎯 全球直连
  - DOMAIN-SUFFIX,dl.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,dl.l.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,googletagmanager.com,🎯 全球直连
  - DOMAIN-SUFFIX,googletagservices.com,🎯 全球直连
  - DOMAIN-SUFFIX,gtm.oasisfeng.com,🎯 全球直连
  - DOMAIN-SUFFIX,mtalk.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,ocsp.pki.goog,🎯 全球直连
  - DOMAIN-SUFFIX,recaptcha.net,🎯 全球直连
  - DOMAIN-SUFFIX,safebrowsing-cache.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,settings.crashlytics.com,🎯 全球直连
  - DOMAIN-SUFFIX,ssl-google-analytics.l.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,toolbarqueries.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,tools.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,tools.l.google.com,🎯 全球直连
  - DOMAIN-SUFFIX,www-googletagmanager.l.google.com,🎯 全球直连
  - DOMAIN,csgo.wmsj.cn,🎯 全球直连
  - DOMAIN,dl.steam.clngaa.com,🎯 全球直连
  - DOMAIN,dl.steam.ksyna.com,🎯 全球直连
  - DOMAIN,dota2.wmsj.cn,🎯 全球直连
  - DOMAIN,st.dl.bscstorage.net,🎯 全球直连
  - DOMAIN,st.dl.eccdnx.com,🎯 全球直连
  - DOMAIN,st.dl.pinyuncloud.com,🎯 全球直连
  - DOMAIN,steampipe.steamcontent.tnkjmec.com,🎯 全球直连
  - DOMAIN,steampowered.com.8686c.com,🎯 全球直连
  - DOMAIN,steamstatic.com.8686c.com,🎯 全球直连
  - DOMAIN,wmsjsteam.com,🎯 全球直连
  - DOMAIN,xz.pphimalayanrt.com,🎯 全球直连
  - DOMAIN-SUFFIX,cm.steampowered.com,🎯 全球直连
  - DOMAIN-SUFFIX,steamchina.com,🎯 全球直连
  - DOMAIN-SUFFIX,steamcontent.com,🎯 全球直连
  - DOMAIN-SUFFIX,steamusercontent.com,🎯 全球直连
  - DOMAIN-KEYWORD,1drv,Ⓜ️ 微软服务
  - DOMAIN-KEYWORD,microsoft,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,aadrm.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,acompli.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,acompli.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,aka.ms,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,akadns.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,aspnetcdn.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,assets-yammer.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,azure.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,azure.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,azureedge.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,azureiotcentral.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,azurerms.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,bing.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,bing.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,bingapis.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,cloudapp.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,cloudappsecurity.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,edgesuite.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,gfx.ms,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,hotmail.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,live.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,live.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,lync.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,msappproxy.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,msauth.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,msauthimages.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,msecnd.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,msedge.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,msft.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,msftauth.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,msftauthimages.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,msftidentity.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,msidentity.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,msn.cn,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,msn.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,msocdn.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,msocsp.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,mstea.ms,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,o365weve.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,oaspapps.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,office.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,office.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,office365.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,officeppe.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,omniroot.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,onedrive.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,onenote.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,onenote.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,onestore.ms,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,outlook.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,outlookmobile.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,phonefactor.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,public-trust.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,sfbassets.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,sfx.ms,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,sharepoint.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,sharepointonline.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,skype.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,skypeassets.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,skypeforbusiness.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,staffhub.ms,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,svc.ms,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,sway-cdn.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,sway-extensions.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,sway.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,trafficmanager.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,uservoice.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,virtualearth.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,visualstudio.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,windows-ppe.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,windows.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,windows.net,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,windowsazure.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,windowsupdate.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,wunderlist.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,yammer.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,yammerusercontent.com,Ⓜ️ 微软服务
  - DOMAIN,apple.comscoreresearch.com,🍎 苹果服务
  - DOMAIN-SUFFIX,aaplimg.com,🍎 苹果服务
  - DOMAIN-SUFFIX,akadns.net,🍎 苹果服务
  - DOMAIN-SUFFIX,apple-cloudkit.com,🍎 苹果服务
  - DOMAIN-SUFFIX,apple-mapkit.com,🍎 苹果服务
  - DOMAIN-SUFFIX,apple.co,🍎 苹果服务
  - DOMAIN-SUFFIX,apple.com,🍎 苹果服务
  - DOMAIN-SUFFIX,apple.com.cn,🍎 苹果服务
  - DOMAIN-SUFFIX,apple.news,🍎 苹果服务
  - DOMAIN-SUFFIX,appstore.com,🍎 苹果服务
  - DOMAIN-SUFFIX,cdn-apple.com,🍎 苹果服务
  - DOMAIN-SUFFIX,crashlytics.com,🍎 苹果服务
  - DOMAIN-SUFFIX,icloud-content.com,🍎 苹果服务
  - DOMAIN-SUFFIX,icloud.com,🍎 苹果服务
  - DOMAIN-SUFFIX,icloud.com.cn,🍎 苹果服务
  - DOMAIN-SUFFIX,itunes.com,🍎 苹果服务
  - DOMAIN-SUFFIX,me.com,🍎 苹果服务
  - DOMAIN-SUFFIX,mzstatic.com,🍎 苹果服务
  - IP-CIDR,17.0.0.0/8,🍎 苹果服务,no-resolve
  - IP-CIDR,63.92.224.0/19,🍎 苹果服务,no-resolve
  - IP-CIDR,65.199.22.0/23,🍎 苹果服务,no-resolve
  - IP-CIDR,139.178.128.0/18,🍎 苹果服务,no-resolve
  - IP-CIDR,144.178.0.0/19,🍎 苹果服务,no-resolve
  - IP-CIDR,144.178.36.0/22,🍎 苹果服务,no-resolve
  - IP-CIDR,144.178.48.0/20,🍎 苹果服务,no-resolve
  - IP-CIDR,192.35.50.0/24,🍎 苹果服务,no-resolve
  - IP-CIDR,198.183.17.0/24,🍎 苹果服务,no-resolve
  - IP-CIDR,205.180.175.0/24,🍎 苹果服务,no-resolve
  - DOMAIN-SUFFIX,t.me,📲 电报信息
  - DOMAIN-SUFFIX,tdesktop.com,📲 电报信息
  - DOMAIN-SUFFIX,telegra.ph,📲 电报信息
  - DOMAIN-SUFFIX,telegram.me,📲 电报信息
  - DOMAIN-SUFFIX,telegram.org,📲 电报信息
  - DOMAIN-SUFFIX,telesco.pe,📲 电报信息
  - IP-CIDR,91.108.0.0/16,📲 电报信息,no-resolve
  - IP-CIDR,109.239.140.0/24,📲 电报信息,no-resolve
  - IP-CIDR,149.154.160.0/20,📲 电报信息,no-resolve
  - IP-CIDR6,2001:67c:4e8::/48,📲 电报信息,no-resolve
  - IP-CIDR6,2001:b28:f23d::/48,📲 电报信息,no-resolve
  - IP-CIDR6,2001:b28:f23f::/48,📲 电报信息,no-resolve
  - DOMAIN-SUFFIX,edgedatg.com,🌍 国外媒体
  - DOMAIN-SUFFIX,go.com,🌍 国外媒体
  - DOMAIN-KEYWORD,abematv.akamaized.net,🌍 国外媒体
  - DOMAIN,api-abematv.bucketeer.jp,🌍 国外媒体
  - DOMAIN-SUFFIX,abema-tv.com,🌍 国外媒体
  - DOMAIN-SUFFIX,abema.io,🌍 国外媒体
  - DOMAIN-SUFFIX,abema.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,ameba.jp,🌍 国外媒体
  - DOMAIN-SUFFIX,hayabusa.io,🌍 国外媒体
  - DOMAIN-SUFFIX,hayabusa.media,🌍 国外媒体
  - DOMAIN-SUFFIX,c4assets.com,🌍 国外媒体
  - DOMAIN-SUFFIX,channel4.com,🌍 国外媒体
  - DOMAIN-KEYWORD,avoddashs,🌍 国外媒体
  - DOMAIN,atv-ps.amazon.com,🌍 国外媒体
  - DOMAIN,avodmp4s3ww-a.akamaihd.net,🌍 国外媒体
  - DOMAIN,d1v5ir2lpwr8os.cloudfront.net,🌍 国外媒体
  - DOMAIN,d1xfray82862hr.cloudfront.net,🌍 国外媒体
  - DOMAIN,d22qjgkvxw22r6.cloudfront.net,🌍 国外媒体
  - DOMAIN,d25xi40x97liuc.cloudfront.net,🌍 国外媒体
  - DOMAIN,d27xxe7juh1us6.cloudfront.net,🌍 国外媒体
  - DOMAIN,d3196yreox78o9.cloudfront.net,🌍 国外媒体
  - DOMAIN,dmqdd6hw24ucf.cloudfront.net,🌍 国外媒体
  - DOMAIN,ktpx.amazon.com,🌍 国外媒体
  - DOMAIN-SUFFIX,aboutamazon.com,🌍 国外媒体
  - DOMAIN-SUFFIX,aiv-cdn.net,🌍 国外媒体
  - DOMAIN-SUFFIX,aiv-delivery.net,🌍 国外媒体
  - DOMAIN-SUFFIX,amazon.jobs,🌍 国外媒体
  - DOMAIN-SUFFIX,amazonuniversity.jobs,🌍 国外媒体
  - DOMAIN-SUFFIX,amazonvideo.com,🌍 国外媒体
  - DOMAIN-SUFFIX,media-amazon.com,🌍 国外媒体
  - DOMAIN-SUFFIX,pv-cdn.net,🌍 国外媒体
  - DOMAIN-SUFFIX,seattlespheres.com,🌍 国外媒体
  - DOMAIN,gspe1-ssl.ls.apple.com,🌍 国外媒体
  - DOMAIN,np-edge.itunes.apple.com,🌍 国外媒体
  - DOMAIN,play-edge.itunes.apple.com,🌍 国外媒体
  - DOMAIN-SUFFIX,tv.apple.com,🌍 国外媒体
  - DOMAIN-KEYWORD,bbcfmt,🌍 国外媒体
  - DOMAIN-KEYWORD,uk-live,🌍 国外媒体
  - DOMAIN,aod-dash-uk-live.akamaized.net,🌍 国外媒体
  - DOMAIN,aod-hls-uk-live.akamaized.net,🌍 国外媒体
  - DOMAIN,vod-dash-uk-live.akamaized.net,🌍 国外媒体
  - DOMAIN,vod-thumb-uk-live.akamaized.net,🌍 国外媒体
  - DOMAIN-SUFFIX,bbc.co,🌍 国外媒体
  - DOMAIN-SUFFIX,bbc.co.uk,🌍 国外媒体
  - DOMAIN-SUFFIX,bbc.com,🌍 国外媒体
  - DOMAIN-SUFFIX,bbc.net.uk,🌍 国外媒体
  - DOMAIN-SUFFIX,bbcfmt.hs.llnwd.net,🌍 国外媒体
  - DOMAIN-SUFFIX,bbci.co,🌍 国外媒体
  - DOMAIN-SUFFIX,bbci.co.uk,🌍 国外媒体
  - DOMAIN-SUFFIX,bidi.net.uk,🌍 国外媒体
  - DOMAIN,bahamut.akamaized.net,🌍 国外媒体
  - DOMAIN,gamer-cds.cdn.hinet.net,🌍 国外媒体
  - DOMAIN,gamer2-cds.cdn.hinet.net,🌍 国外媒体
  - DOMAIN-SUFFIX,bahamut.com.tw,🌍 国外媒体
  - DOMAIN-SUFFIX,gamer.com.tw,🌍 国外媒体
  - DOMAIN-KEYWORD,voddazn,🌍 国外媒体
  - DOMAIN,d151l6v8er5bdm.cloudfront.net,🌍 国外媒体
  - DOMAIN-SUFFIX,d151l6v8er5bdm.cloudfront.net,🌍 国外媒体
  - DOMAIN-SUFFIX,d1sgwhnao7452x.cloudfront.net,🌍 国外媒体
  - DOMAIN-SUFFIX,dazn-api.com,🌍 国外媒体
  - DOMAIN-SUFFIX,dazn.com,🌍 国外媒体
  - DOMAIN-SUFFIX,dazndn.com,🌍 国外媒体
  - DOMAIN-SUFFIX,dcblivedazn.akamaized.net,🌍 国外媒体
  - DOMAIN-SUFFIX,indazn.com,🌍 国外媒体
  - DOMAIN-SUFFIX,indaznlab.com,🌍 国外媒体
  - DOMAIN-SUFFIX,sentry.io,🌍 国外媒体
  - DOMAIN-SUFFIX,deezer.com,🌍 国外媒体
  - DOMAIN-SUFFIX,dzcdn.net,🌍 国外媒体
  - DOMAIN-SUFFIX,disco-api.com,🌍 国外媒体
  - DOMAIN-SUFFIX,discovery.com,🌍 国外媒体
  - DOMAIN-SUFFIX,uplynk.com,🌍 国外媒体
  - DOMAIN,cdn.registerdisney.go.com,🌍 国外媒体
  - DOMAIN-SUFFIX,adobedtm.com,🌍 国外媒体
  - DOMAIN-SUFFIX,bam.nr-data.net,🌍 国外媒体
  - DOMAIN-SUFFIX,bamgrid.com,🌍 国外媒体
  - DOMAIN-SUFFIX,braze.com,🌍 国外媒体
  - DOMAIN-SUFFIX,cdn.optimizely.com,🌍 国外媒体
  - DOMAIN-SUFFIX,cdn.registerdisney.go.com,🌍 国外媒体
  - DOMAIN-SUFFIX,cws.conviva.com,🌍 国外媒体
  - DOMAIN-SUFFIX,d9.flashtalking.com,🌍 国外媒体
  - DOMAIN-SUFFIX,disney-plus.net,🌍 国外媒体
  - DOMAIN-SUFFIX,disney-portal.my.onetrust.com,🌍 国外媒体
  - DOMAIN-SUFFIX,disney.demdex.net,🌍 国外媒体
  - DOMAIN-SUFFIX,disney.my.sentry.io,🌍 国外媒体
  - DOMAIN-SUFFIX,disneyplus.bn5x.net,🌍 国外媒体
  - DOMAIN-SUFFIX,disneyplus.com,🌍 国外媒体
  - DOMAIN-SUFFIX,disneyplus.com.ssl.sc.omtrdc.net,🌍 国外媒体
  - DOMAIN-SUFFIX,disneystreaming.com,🌍 国外媒体
  - DOMAIN-SUFFIX,dssott.com,🌍 国外媒体
  - DOMAIN-SUFFIX,execute-api.us-east-1.amazonaws.com,🌍 国外媒体
  - DOMAIN-SUFFIX,js-agent.newrelic.com,🌍 国外媒体
  - DOMAIN,bcbolt446c5271-a.akamaihd.net,🌍 国外媒体
  - DOMAIN,content.jwplatform.com,🌍 国外媒体
  - DOMAIN,edge.api.brightcove.com,🌍 国外媒体
  - DOMAIN,videos-f.jwpsrv.com,🌍 国外媒体
  - DOMAIN-SUFFIX,encoretvb.com,🌍 国外媒体
  - DOMAIN-SUFFIX,fox.com,🌍 国外媒体
  - DOMAIN-SUFFIX,foxdcg.com,🌍 国外媒体
  - DOMAIN-SUFFIX,uplynk.com,🌍 国外媒体
  - DOMAIN-SUFFIX,hbo.com,🌍 国外媒体
  - DOMAIN-SUFFIX,hbogo.com,🌍 国外媒体
  - DOMAIN-SUFFIX,hbomax.com,🌍 国外媒体
  - DOMAIN-SUFFIX,hbomaxcdn.com,🌍 国外媒体
  - DOMAIN-SUFFIX,hbonow.com,🌍 国外媒体
  - DOMAIN-KEYWORD,.hbogoasia.,🌍 国外媒体
  - DOMAIN-KEYWORD,hbogoasia,🌍 国外媒体
  - DOMAIN,44wilhpljf.execute-api.ap-southeast-1.amazonaws.com,🌍 国外媒体
  - DOMAIN,bcbolthboa-a.akamaihd.net,🌍 国外媒体
  - DOMAIN,cf-images.ap-southeast-1.prod.boltdns.net,🌍 国外媒体
  - DOMAIN,dai3fd1oh325y.cloudfront.net,🌍 国外媒体
  - DOMAIN,hboasia1-i.akamaihd.net,🌍 国外媒体
  - DOMAIN,hboasia2-i.akamaihd.net,🌍 国外媒体
  - DOMAIN,hboasia3-i.akamaihd.net,🌍 国外媒体
  - DOMAIN,hboasia4-i.akamaihd.net,🌍 国外媒体
  - DOMAIN,hboasia5-i.akamaihd.net,🌍 国外媒体
  - DOMAIN,hboasialive.akamaized.net,🌍 国外媒体
  - DOMAIN,hbogoprod-vod.akamaized.net,🌍 国外媒体
  - DOMAIN,hbolb.onwardsmg.com,🌍 国外媒体
  - DOMAIN,hbounify-prod.evergent.com,🌍 国外媒体
  - DOMAIN,players.brightcove.net,🌍 国外媒体
  - DOMAIN,s3-ap-southeast-1.amazonaws.com,🌍 国外媒体
  - DOMAIN-SUFFIX,hboasia.com,🌍 国外媒体
  - DOMAIN-SUFFIX,hbogoasia.com,🌍 国外媒体
  - DOMAIN-SUFFIX,hbogoasia.hk,🌍 国外媒体
  - DOMAIN-SUFFIX,5itv.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,ocnttv.com,🌍 国外媒体
  - DOMAIN-SUFFIX,cws-hulu.conviva.com,🌍 国外媒体
  - DOMAIN-SUFFIX,hulu.com,🌍 国外媒体
  - DOMAIN-SUFFIX,hulu.hb.omtrdc.net,🌍 国外媒体
  - DOMAIN-SUFFIX,hulu.sc.omtrdc.net,🌍 国外媒体
  - DOMAIN-SUFFIX,huluad.com,🌍 国外媒体
  - DOMAIN-SUFFIX,huluim.com,🌍 国外媒体
  - DOMAIN-SUFFIX,hulustream.com,🌍 国外媒体
  - DOMAIN-SUFFIX,happyon.jp,🌍 国外媒体
  - DOMAIN-SUFFIX,hjholdings.jp,🌍 国外媒体
  - DOMAIN-SUFFIX,hulu.jp,🌍 国外媒体
  - DOMAIN-SUFFIX,prod.hjholdings.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,streaks.jp,🌍 国外媒体
  - DOMAIN-SUFFIX,yb.uncn.jp,🌍 国外媒体
  - DOMAIN,itvpnpmobile-a.akamaihd.net,🌍 国外媒体
  - DOMAIN-SUFFIX,itv.com,🌍 国外媒体
  - DOMAIN-SUFFIX,itvstatic.com,🌍 国外媒体
  - DOMAIN-KEYWORD,jooxweb-api,🌍 国外媒体
  - DOMAIN-SUFFIX,joox.com,🌍 国外媒体
  - DOMAIN-KEYWORD,japonx,🌍 国外媒体
  - DOMAIN-KEYWORD,japronx,🌍 国外媒体
  - DOMAIN-SUFFIX,japonx.com,🌍 国外媒体
  - DOMAIN-SUFFIX,japonx.net,🌍 国外媒体
  - DOMAIN-SUFFIX,japonx.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,japonx.vip,🌍 国外媒体
  - DOMAIN-SUFFIX,japronx.com,🌍 国外媒体
  - DOMAIN-SUFFIX,japronx.net,🌍 国外媒体
  - DOMAIN-SUFFIX,japronx.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,japronx.vip,🌍 国外媒体
  - DOMAIN-SUFFIX,kfs.io,🌍 国外媒体
  - DOMAIN-SUFFIX,kkbox.com,🌍 国外媒体
  - DOMAIN-SUFFIX,kkbox.com.tw,🌍 国外媒体
  - DOMAIN,kktv-theater.kk.stream,🌍 国外媒体
  - DOMAIN,theater-kktv.cdn.hinet.net,🌍 国外媒体
  - DOMAIN-SUFFIX,kktv.com.tw,🌍 国外媒体
  - DOMAIN-SUFFIX,kktv.me,🌍 国外媒体
  - DOMAIN,litvfreemobile-hichannel.cdn.hinet.net,🌍 国外媒体
  - DOMAIN-SUFFIX,litv.tv,🌍 国外媒体
  - DOMAIN,d3c7rimkq79yfu.cloudfront.net,🌍 国外媒体
  - DOMAIN-SUFFIX,d3c7rimkq79yfu.cloudfront.net,🌍 国外媒体
  - DOMAIN-SUFFIX,linetv.tw,🌍 国外媒体
  - DOMAIN-SUFFIX,profile.line-scdn.net,🌍 国外媒体
  - DOMAIN,d349g9zuie06uo.cloudfront.net,🌍 国外媒体
  - DOMAIN-SUFFIX,channel5.com,🌍 国外媒体
  - DOMAIN-SUFFIX,my5.tv,🌍 国外媒体
  - DOMAIN-KEYWORD,nowtv100,🌍 国外媒体
  - DOMAIN-KEYWORD,rthklive,🌍 国外媒体
  - DOMAIN,mytvsuperlimited.hb.omtrdc.net,🌍 国外媒体
  - DOMAIN,mytvsuperlimited.sc.omtrdc.net,🌍 国外媒体
  - DOMAIN-SUFFIX,mytvsuper.com,🌍 国外媒体
  - DOMAIN-SUFFIX,tvb.com,🌍 国外媒体
  - DOMAIN-KEYWORD,apiproxy-device-prod-nlb-,🌍 国外媒体
  - DOMAIN-KEYWORD,dualstack.apiproxy-,🌍 国外媒体
  - DOMAIN-KEYWORD,netflixdnstest,🌍 国外媒体
  - DOMAIN,netflix.com.edgesuite.net,🌍 国外媒体
  - DOMAIN-SUFFIX,fast.com,🌍 国外媒体
  - DOMAIN-SUFFIX,netflix.com,🌍 国外媒体
  - DOMAIN-SUFFIX,netflix.net,🌍 国外媒体
  - DOMAIN-SUFFIX,netflixdnstest0.com,🌍 国外媒体
  - DOMAIN-SUFFIX,netflixdnstest1.com,🌍 国外媒体
  - DOMAIN-SUFFIX,netflixdnstest2.com,🌍 国外媒体
  - DOMAIN-SUFFIX,netflixdnstest3.com,🌍 国外媒体
  - DOMAIN-SUFFIX,netflixdnstest4.com,🌍 国外媒体
  - DOMAIN-SUFFIX,netflixdnstest5.com,🌍 国外媒体
  - DOMAIN-SUFFIX,netflixdnstest6.com,🌍 国外媒体
  - DOMAIN-SUFFIX,netflixdnstest7.com,🌍 国外媒体
  - DOMAIN-SUFFIX,netflixdnstest8.com,🌍 国外媒体
  - DOMAIN-SUFFIX,netflixdnstest9.com,🌍 国外媒体
  - DOMAIN-SUFFIX,nflxext.com,🌍 国外媒体
  - DOMAIN-SUFFIX,nflximg.com,🌍 国外媒体
  - DOMAIN-SUFFIX,nflximg.net,🌍 国外媒体
  - DOMAIN-SUFFIX,nflxso.net,🌍 国外媒体
  - DOMAIN-SUFFIX,nflxvideo.net,🌍 国外媒体
  - IP-CIDR,8.41.4.0/24,🌍 国外媒体,no-resolve
  - IP-CIDR,23.246.0.0/18,🌍 国外媒体,no-resolve
  - IP-CIDR,37.77.184.0/21,🌍 国外媒体,no-resolve
  - IP-CIDR,38.72.126.0/24,🌍 国外媒体,no-resolve
  - IP-CIDR,45.57.0.0/17,🌍 国外媒体,no-resolve
  - IP-CIDR,64.120.128.0/17,🌍 国外媒体,no-resolve
  - IP-CIDR,66.197.128.0/17,🌍 国外媒体,no-resolve
  - IP-CIDR,69.53.224.0/19,🌍 国外媒体,no-resolve
  - IP-CIDR,103.87.204.0/22,🌍 国外媒体,no-resolve
  - IP-CIDR,108.175.32.0/20,🌍 国外媒体,no-resolve
  - IP-CIDR,185.2.220.0/22,🌍 国外媒体,no-resolve
  - IP-CIDR,185.9.188.0/22,🌍 国外媒体,no-resolve
  - IP-CIDR,192.173.64.0/18,🌍 国外媒体,no-resolve
  - IP-CIDR,198.38.96.0/19,🌍 国外媒体,no-resolve
  - IP-CIDR,198.45.48.0/20,🌍 国外媒体,no-resolve
  - IP-CIDR,207.45.72.0/22,🌍 国外媒体,no-resolve
  - IP-CIDR,208.75.76.0/22,🌍 国外媒体,no-resolve
  - DOMAIN-SUFFIX,dmc.nico,🌍 国外媒体
  - DOMAIN-SUFFIX,nicovideo.jp,🌍 国外媒体
  - DOMAIN-SUFFIX,nimg.jp,🌍 国外媒体
  - DOMAIN-KEYWORD,nivod,🌍 国外媒体
  - DOMAIN-SUFFIX,biggggg.com,🌍 国外媒体
  - DOMAIN-SUFFIX,mudvod.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,nbys.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,nbys1.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,nbyy.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,newpppp.com,🌍 国外媒体
  - DOMAIN-SUFFIX,nivod.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,nivodi.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,nivodz.com,🌍 国外媒体
  - DOMAIN-SUFFIX,vod360.net,🌍 国外媒体
  - DOMAIN-KEYWORD,olevod,🌍 国外媒体
  - DOMAIN-SUFFIX,haiwaikan.com,🌍 国外媒体
  - DOMAIN-SUFFIX,iole.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,olehd.com,🌍 国外媒体
  - DOMAIN-SUFFIX,olelive.com,🌍 国外媒体
  - DOMAIN-SUFFIX,olevod.com,🌍 国外媒体
  - DOMAIN-SUFFIX,olevod.io,🌍 国外媒体
  - DOMAIN-SUFFIX,olevod.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,olevodtv.com,🌍 国外媒体
  - DOMAIN-KEYWORD,openai,🌍 国外媒体
  - DOMAIN-SUFFIX,ai.com,🌍 国外媒体
  - DOMAIN-SUFFIX,auth0.com,🌍 国外媒体
  - DOMAIN-SUFFIX,challenges.cloudflare.com,🌍 国外媒体
  - DOMAIN-SUFFIX,client-api.arkoselabs.com,🌍 国外媒体
  - DOMAIN-SUFFIX,events.statsigapi.net,🌍 国外媒体
  - DOMAIN-SUFFIX,featuregates.org,🌍 国外媒体
  - DOMAIN-SUFFIX,identrust.com,🌍 国外媒体
  - DOMAIN-SUFFIX,intercom.io,🌍 国外媒体
  - DOMAIN-SUFFIX,intercomcdn.com,🌍 国外媒体
  - DOMAIN-SUFFIX,openai.com,🌍 国外媒体
  - DOMAIN-SUFFIX,openaiapi-site.azureedge.net,🌍 国外媒体
  - DOMAIN-SUFFIX,sentry.io,🌍 国外媒体
  - DOMAIN-SUFFIX,stripe.com,🌍 国外媒体
  - DOMAIN-SUFFIX,pbs.org,🌍 国外媒体
  - DOMAIN-SUFFIX,pandora.com,🌍 国外媒体
  - DOMAIN-SUFFIX,phncdn.com,🌍 国外媒体
  - DOMAIN-SUFFIX,phprcdn.com,🌍 国外媒体
  - DOMAIN-SUFFIX,pornhub.com,🌍 国外媒体
  - DOMAIN-SUFFIX,pornhubpremium.com,🌍 国外媒体
  - DOMAIN-SUFFIX,qobuz.com,🌍 国外媒体
  - DOMAIN-SUFFIX,p-cdn.us,🌍 国外媒体
  - DOMAIN-SUFFIX,sndcdn.com,🌍 国外媒体
  - DOMAIN-SUFFIX,soundcloud.com,🌍 国外媒体
  - DOMAIN-KEYWORD,-spotify-,🌍 国外媒体
  - DOMAIN-KEYWORD,spotify.com,🌍 国外媒体
  - DOMAIN-SUFFIX,pscdn.co,🌍 国外媒体
  - DOMAIN-SUFFIX,scdn.co,🌍 国外媒体
  - DOMAIN-SUFFIX,spoti.fi,🌍 国外媒体
  - DOMAIN-SUFFIX,spotify.com,🌍 国外媒体
  - DOMAIN-SUFFIX,spotifycdn.com,🌍 国外媒体
  - DOMAIN-SUFFIX,spotifycdn.net,🌍 国外媒体
  - DOMAIN-SUFFIX,tidal-cms.s3.amazonaws.com,🌍 国外媒体
  - DOMAIN-SUFFIX,tidal.com,🌍 国外媒体
  - DOMAIN-SUFFIX,tidalhifi.com,🌍 国外媒体
  - DOMAIN,hamifans.emome.net,🌍 国外媒体
  - DOMAIN-SUFFIX,skyking.com.tw,🌍 国外媒体
  - DOMAIN-KEYWORD,tiktokcdn,🌍 国外媒体
  - DOMAIN-SUFFIX,byteoversea.com,🌍 国外媒体
  - DOMAIN-SUFFIX,ibytedtos.com,🌍 国外媒体
  - DOMAIN-SUFFIX,ipstatp.com,🌍 国外媒体
  - DOMAIN-SUFFIX,muscdn.com,🌍 国外媒体
  - DOMAIN-SUFFIX,musical.ly,🌍 国外媒体
  - DOMAIN-SUFFIX,tik-tokapi.com,🌍 国外媒体
  - DOMAIN-SUFFIX,tiktok.com,🌍 国外媒体
  - DOMAIN-SUFFIX,tiktokcdn.com,🌍 国外媒体
  - DOMAIN-SUFFIX,tiktokv.com,🌍 国外媒体
  - DOMAIN-KEYWORD,ttvnw,🌍 国外媒体
  - DOMAIN-SUFFIX,ext-twitch.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,jtvnw.net,🌍 国外媒体
  - DOMAIN-SUFFIX,ttvnw.net,🌍 国外媒体
  - DOMAIN-SUFFIX,twitch-ext.rootonline.de,🌍 国外媒体
  - DOMAIN-SUFFIX,twitch.tv,🌍 国外媒体
  - DOMAIN-SUFFIX,twitchcdn.net,🌍 国外媒体
  - PROCESS-NAME,com.viu.pad,🌍 国外媒体
  - PROCESS-NAME,com.viu.phone,🌍 国外媒体
  - PROCESS-NAME,com.vuclip.viu,🌍 国外媒体
  - DOMAIN,api.viu.now.com,🌍 国外媒体
  - DOMAIN,d1k2us671qcoau.cloudfront.net,🌍 国外媒体
  - DOMAIN,d2anahhhmp1ffz.cloudfront.net,🌍 国外媒体
  - DOMAIN,dfp6rglgjqszk.cloudfront.net,🌍 国外媒体
  - DOMAIN-SUFFIX,cognito-identity.us-east-1.amazonaws.com,🌍 国外媒体
  - DOMAIN-SUFFIX,d1k2us671qcoau.cloudfront.net,🌍 国外媒体
  - DOMAIN-SUFFIX,d2anahhhmp1ffz.cloudfront.net,🌍 国外媒体
  - DOMAIN-SUFFIX,dfp6rglgjqszk.cloudfront.net,🌍 国外媒体
  - DOMAIN-SUFFIX,mobileanalytics.us-east-1.amazonaws.com,🌍 国外媒体
  - DOMAIN-SUFFIX,viu.com,🌍 国外媒体
  - DOMAIN-SUFFIX,viu.now.com,🌍 国外媒体
  - DOMAIN-SUFFIX,viu.tv,🌍 国外媒体
  - DOMAIN-KEYWORD,youtube,🌍 国外媒体
  - DOMAIN,youtubei.googleapis.com,🌍 国外媒体
  - DOMAIN,yt3.ggpht.com,🌍 国外媒体
  - DOMAIN-SUFFIX,googlevideo.com,🌍 国外媒体
  - DOMAIN-SUFFIX,gvt2.com,🌍 国外媒体
  - DOMAIN-SUFFIX,withyoutube.com,🌍 国外媒体
  - DOMAIN-SUFFIX,youtu.be,🌍 国外媒体
  - DOMAIN-SUFFIX,youtube-nocookie.com,🌍 国外媒体
  - DOMAIN-SUFFIX,youtube.com,🌍 国外媒体
  - DOMAIN-SUFFIX,youtubeeducation.com,🌍 国外媒体
  - DOMAIN-SUFFIX,youtubegaming.com,🌍 国外媒体
  - DOMAIN-SUFFIX,youtubekids.com,🌍 国外媒体
  - DOMAIN-SUFFIX,yt.be,🌍 国外媒体
  - DOMAIN-SUFFIX,ytimg.com,🌍 国外媒体
  - DOMAIN,music.youtube.com,🌍 国外媒体
  - DOMAIN-SUFFIX,1password.com,🚀 节点选择
  - DOMAIN-SUFFIX,adguard.org,🚀 节点选择
  - DOMAIN-SUFFIX,bit.no.com,🚀 节点选择
  - DOMAIN-SUFFIX,btlibrary.me,🚀 节点选择
  - DOMAIN-SUFFIX,cloudcone.com,🚀 节点选择
  - DOMAIN-SUFFIX,dubox.com,🚀 节点选择
  - DOMAIN-SUFFIX,gameloft.com,🚀 节点选择
  - DOMAIN-SUFFIX,garena.com,🚀 节点选择
  - DOMAIN-SUFFIX,hoyolab.com,🚀 节点选择
  - DOMAIN-SUFFIX,inoreader.com,🚀 节点选择
  - DOMAIN-SUFFIX,ip138.com,🚀 节点选择
  - DOMAIN-SUFFIX,linkedin.com,🚀 节点选择
  - DOMAIN-SUFFIX,myteamspeak.com,🚀 节点选择
  - DOMAIN-SUFFIX,notion.so,🚀 节点选择
  - DOMAIN-SUFFIX,ping.pe,🚀 节点选择
  - DOMAIN-SUFFIX,reddit.com,🚀 节点选择
  - DOMAIN-SUFFIX,teddysun.com,🚀 节点选择
  - DOMAIN-SUFFIX,tumbex.com,🚀 节点选择
  - DOMAIN-SUFFIX,twdvd.com,🚀 节点选择
  - DOMAIN-SUFFIX,unsplash.com,🚀 节点选择
  - DOMAIN-SUFFIX,eu,🚀 节点选择
  - DOMAIN-SUFFIX,hk,🚀 节点选择
  - DOMAIN-SUFFIX,jp,🚀 节点选择
  - DOMAIN-SUFFIX,kr,🚀 节点选择
  - DOMAIN-SUFFIX,sg,🚀 节点选择
  - DOMAIN-SUFFIX,tw,🚀 节点选择
  - DOMAIN-SUFFIX,uk,🚀 节点选择
  - DOMAIN-KEYWORD,1e100,🚀 节点选择
  - DOMAIN-KEYWORD,abema,🚀 节点选择
  - DOMAIN-KEYWORD,appledaily,🚀 节点选择
  - DOMAIN-KEYWORD,avtb,🚀 节点选择
  - DOMAIN-KEYWORD,beetalk,🚀 节点选择
  - DOMAIN-KEYWORD,blogspot,🚀 节点选择
  - DOMAIN-KEYWORD,dropbox,🚀 节点选择
  - DOMAIN-KEYWORD,facebook,🚀 节点选择
  - DOMAIN-KEYWORD,fbcdn,🚀 节点选择
  - DOMAIN-KEYWORD,github,🚀 节点选择
  - DOMAIN-KEYWORD,gmail,🚀 节点选择
  - DOMAIN-KEYWORD,google,🚀 节点选择
  - DOMAIN-KEYWORD,instagram,🚀 节点选择
  - DOMAIN-KEYWORD,porn,🚀 节点选择
  - DOMAIN-KEYWORD,sci-hub,🚀 节点选择
  - DOMAIN-KEYWORD,spotify,🚀 节点选择
  - DOMAIN-KEYWORD,telegram,🚀 节点选择
  - DOMAIN-KEYWORD,twitter,🚀 节点选择
  - DOMAIN-KEYWORD,whatsapp,🚀 节点选择
  - DOMAIN-KEYWORD,youtube,🚀 节点选择
  - DOMAIN-SUFFIX,4sqi.net,🚀 节点选择
  - DOMAIN-SUFFIX,a248.e.akamai.net,🚀 节点选择
  - DOMAIN-SUFFIX,adobedtm.com,🚀 节点选择
  - DOMAIN-SUFFIX,ampproject.org,🚀 节点选择
  - DOMAIN-SUFFIX,android.com,🚀 节点选择
  - DOMAIN-SUFFIX,aolcdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,apkmirror.com,🚀 节点选择
  - DOMAIN-SUFFIX,apkpure.com,🚀 节点选择
  - DOMAIN-SUFFIX,app-measurement.com,🚀 节点选择
  - DOMAIN-SUFFIX,appspot.com,🚀 节点选择
  - DOMAIN-SUFFIX,archive.org,🚀 节点选择
  - DOMAIN-SUFFIX,armorgames.com,🚀 节点选择
  - DOMAIN-SUFFIX,aspnetcdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,awsstatic.com,🚀 节点选择
  - DOMAIN-SUFFIX,azureedge.net,🚀 节点选择
  - DOMAIN-SUFFIX,azurewebsites.net,🚀 节点选择
  - DOMAIN-SUFFIX,bandwagonhost.com,🚀 节点选择
  - DOMAIN-SUFFIX,bing.com,🚀 节点选择
  - DOMAIN-SUFFIX,bkrtx.com,🚀 节点选择
  - DOMAIN-SUFFIX,blogcdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,blogger.com,🚀 节点选择
  - DOMAIN-SUFFIX,blogsmithmedia.com,🚀 节点选择
  - DOMAIN-SUFFIX,blogspot.com,🚀 节点选择
  - DOMAIN-SUFFIX,blogspot.hk,🚀 节点选择
  - DOMAIN-SUFFIX,blogspot.jp,🚀 节点选择
  - DOMAIN-SUFFIX,bloomberg.cn,🚀 节点选择
  - DOMAIN-SUFFIX,bloomberg.com,🚀 节点选择
  - DOMAIN-SUFFIX,box.com,🚀 节点选择
  - DOMAIN-SUFFIX,cachefly.net,🚀 节点选择
  - DOMAIN-SUFFIX,cdnst.net,🚀 节点选择
  - DOMAIN-SUFFIX,cloudfront.net,🚀 节点选择
  - DOMAIN-SUFFIX,comodoca.com,🚀 节点选择
  - DOMAIN-SUFFIX,daum.net,🚀 节点选择
  - DOMAIN-SUFFIX,deskconnect.com,🚀 节点选择
  - DOMAIN-SUFFIX,disqus.com,🚀 节点选择
  - DOMAIN-SUFFIX,disquscdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,dropbox.com,🚀 节点选择
  - DOMAIN-SUFFIX,dropboxapi.com,🚀 节点选择
  - DOMAIN-SUFFIX,dropboxstatic.com,🚀 节点选择
  - DOMAIN-SUFFIX,dropboxusercontent.com,🚀 节点选择
  - DOMAIN-SUFFIX,duckduckgo.com,🚀 节点选择
  - DOMAIN-SUFFIX,edgecastcdn.net,🚀 节点选择
  - DOMAIN-SUFFIX,edgekey.net,🚀 节点选择
  - DOMAIN-SUFFIX,edgesuite.net,🚀 节点选择
  - DOMAIN-SUFFIX,eurekavpt.com,🚀 节点选择
  - DOMAIN-SUFFIX,fastmail.com,🚀 节点选择
  - DOMAIN-SUFFIX,firebaseio.com,🚀 节点选择
  - DOMAIN-SUFFIX,flickr.com,🚀 节点选择
  - DOMAIN-SUFFIX,flipboard.com,🚀 节点选择
  - DOMAIN-SUFFIX,gfx.ms,🚀 节点选择
  - DOMAIN-SUFFIX,gongm.in,🚀 节点选择
  - DOMAIN-SUFFIX,hulu.com,🚀 节点选择
  - DOMAIN-SUFFIX,id.heroku.com,🚀 节点选择
  - DOMAIN-SUFFIX,io.io,🚀 节点选择
  - DOMAIN-SUFFIX,issuu.com,🚀 节点选择
  - DOMAIN-SUFFIX,ixquick.com,🚀 节点选择
  - DOMAIN-SUFFIX,jtvnw.net,🚀 节点选择
  - DOMAIN-SUFFIX,kat.cr,🚀 节点选择
  - DOMAIN-SUFFIX,kik.com,🚀 节点选择
  - DOMAIN-SUFFIX,kobo.com,🚀 节点选择
  - DOMAIN-SUFFIX,kobobooks.com,🚀 节点选择
  - DOMAIN-SUFFIX,licdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,live.net,🚀 节点选择
  - DOMAIN-SUFFIX,livefilestore.com,🚀 节点选择
  - DOMAIN-SUFFIX,llnwd.net,🚀 节点选择
  - DOMAIN-SUFFIX,macrumors.com,🚀 节点选择
  - DOMAIN-SUFFIX,medium.com,🚀 节点选择
  - DOMAIN-SUFFIX,mega.nz,🚀 节点选择
  - DOMAIN-SUFFIX,megaupload.com,🚀 节点选择
  - DOMAIN-SUFFIX,messenger.com,🚀 节点选择
  - DOMAIN-SUFFIX,netdna-cdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,nintendo.net,🚀 节点选择
  - DOMAIN-SUFFIX,nsstatic.net,🚀 节点选择
  - DOMAIN-SUFFIX,nytstyle.com,🚀 节点选择
  - DOMAIN-SUFFIX,overcast.fm,🚀 节点选择
  - DOMAIN-SUFFIX,openvpn.net,🚀 节点选择
  - DOMAIN-SUFFIX,periscope.tv,🚀 节点选择
  - DOMAIN-SUFFIX,pinimg.com,🚀 节点选择
  - DOMAIN-SUFFIX,pinterest.com,🚀 节点选择
  - DOMAIN-SUFFIX,potato.im,🚀 节点选择
  - DOMAIN-SUFFIX,prfct.co,🚀 节点选择
  - DOMAIN-SUFFIX,pscp.tv,🚀 节点选择
  - DOMAIN-SUFFIX,quora.com,🚀 节点选择
  - DOMAIN-SUFFIX,resilio.com,🚀 节点选择
  - DOMAIN-SUFFIX,sfx.ms,🚀 节点选择
  - DOMAIN-SUFFIX,shadowsocks.org,🚀 节点选择
  - DOMAIN-SUFFIX,slack-edge.com,🚀 节点选择
  - DOMAIN-SUFFIX,smartdnsproxy.com,🚀 节点选择
  - DOMAIN-SUFFIX,sndcdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,soundcloud.com,🚀 节点选择
  - DOMAIN-SUFFIX,startpage.com,🚀 节点选择
  - DOMAIN-SUFFIX,staticflickr.com,🚀 节点选择
  - DOMAIN-SUFFIX,symauth.com,🚀 节点选择
  - DOMAIN-SUFFIX,symcb.com,🚀 节点选择
  - DOMAIN-SUFFIX,symcd.com,🚀 节点选择
  - DOMAIN-SUFFIX,textnow.com,🚀 节点选择
  - DOMAIN-SUFFIX,textnow.me,🚀 节点选择
  - DOMAIN-SUFFIX,thefacebook.com,🚀 节点选择
  - DOMAIN-SUFFIX,thepiratebay.org,🚀 节点选择
  - DOMAIN-SUFFIX,torproject.org,🚀 节点选择
  - DOMAIN-SUFFIX,trustasiassl.com,🚀 节点选择
  - DOMAIN-SUFFIX,tumblr.co,🚀 节点选择
  - DOMAIN-SUFFIX,tumblr.com,🚀 节点选择
  - DOMAIN-SUFFIX,tvb.com,🚀 节点选择
  - DOMAIN-SUFFIX,txmblr.com,🚀 节点选择
  - DOMAIN-SUFFIX,v2ex.com,🚀 节点选择
  - DOMAIN-SUFFIX,vimeo.com,🚀 节点选择
  - DOMAIN-SUFFIX,vine.co,🚀 节点选择
  - DOMAIN-SUFFIX,vox-cdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,amazon.co.jp,🚀 节点选择
  - DOMAIN-SUFFIX,amazon.com,🚀 节点选择
  - DOMAIN-SUFFIX,amazonaws.com,🚀 节点选择
  - IP-CIDR,13.32.0.0/15,🚀 节点选择,no-resolve
  - IP-CIDR,13.35.0.0/17,🚀 节点选择,no-resolve
  - IP-CIDR,18.184.0.0/15,🚀 节点选择,no-resolve
  - IP-CIDR,18.194.0.0/15,🚀 节点选择,no-resolve
  - IP-CIDR,18.208.0.0/13,🚀 节点选择,no-resolve
  - IP-CIDR,18.232.0.0/14,🚀 节点选择,no-resolve
  - IP-CIDR,52.58.0.0/15,🚀 节点选择,no-resolve
  - IP-CIDR,52.74.0.0/16,🚀 节点选择,no-resolve
  - IP-CIDR,52.77.0.0/16,🚀 节点选择,no-resolve
  - IP-CIDR,52.84.0.0/15,🚀 节点选择,no-resolve
  - IP-CIDR,52.200.0.0/13,🚀 节点选择,no-resolve
  - IP-CIDR,54.93.0.0/16,🚀 节点选择,no-resolve
  - IP-CIDR,54.156.0.0/14,🚀 节点选择,no-resolve
  - IP-CIDR,54.226.0.0/15,🚀 节点选择,no-resolve
  - IP-CIDR,54.230.156.0/22,🚀 节点选择,no-resolve
  - DOMAIN-KEYWORD,uk-live,🚀 节点选择
  - DOMAIN-SUFFIX,bbc.co,🚀 节点选择
  - DOMAIN-SUFFIX,bbc.com,🚀 节点选择
  - DOMAIN-SUFFIX,apache.org,🚀 节点选择
  - DOMAIN-SUFFIX,docker.com,🚀 节点选择
  - DOMAIN-SUFFIX,elastic.co,🚀 节点选择
  - DOMAIN-SUFFIX,elastic.com,🚀 节点选择
  - DOMAIN-SUFFIX,gcr.io,🚀 节点选择
  - DOMAIN-SUFFIX,gitlab.com,🚀 节点选择
  - DOMAIN-SUFFIX,gitlab.io,🚀 节点选择
  - DOMAIN-SUFFIX,jitpack.io,🚀 节点选择
  - DOMAIN-SUFFIX,maven.org,🚀 节点选择
  - DOMAIN-SUFFIX,medium.com,🚀 节点选择
  - DOMAIN-SUFFIX,mvnrepository.com,🚀 节点选择
  - DOMAIN-SUFFIX,quay.io,🚀 节点选择
  - DOMAIN-SUFFIX,reddit.com,🚀 节点选择
  - DOMAIN-SUFFIX,redhat.com,🚀 节点选择
  - DOMAIN-SUFFIX,sonatype.org,🚀 节点选择
  - DOMAIN-SUFFIX,sourcegraph.com,🚀 节点选择
  - DOMAIN-SUFFIX,spring.io,🚀 节点选择
  - DOMAIN-SUFFIX,spring.net,🚀 节点选择
  - DOMAIN-SUFFIX,stackoverflow.com,🚀 节点选择
  - DOMAIN-SUFFIX,discord.co,🚀 节点选择
  - DOMAIN-SUFFIX,discord.com,🚀 节点选择
  - DOMAIN-SUFFIX,discord.gg,🚀 节点选择
  - DOMAIN-SUFFIX,discord.media,🚀 节点选择
  - DOMAIN-SUFFIX,discordapp.com,🚀 节点选择
  - DOMAIN-SUFFIX,discordapp.net,🚀 节点选择
  - DOMAIN-SUFFIX,facebook.com,🚀 节点选择
  - DOMAIN-SUFFIX,fb.com,🚀 节点选择
  - DOMAIN-SUFFIX,fb.me,🚀 节点选择
  - DOMAIN-SUFFIX,fbcdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,fbcdn.net,🚀 节点选择
  - IP-CIDR,31.13.24.0/21,🚀 节点选择,no-resolve
  - IP-CIDR,31.13.64.0/18,🚀 节点选择,no-resolve
  - IP-CIDR,45.64.40.0/22,🚀 节点选择,no-resolve
  - IP-CIDR,66.220.144.0/20,🚀 节点选择,no-resolve
  - IP-CIDR,69.63.176.0/20,🚀 节点选择,no-resolve
  - IP-CIDR,69.171.224.0/19,🚀 节点选择,no-resolve
  - IP-CIDR,74.119.76.0/22,🚀 节点选择,no-resolve
  - IP-CIDR,103.4.96.0/22,🚀 节点选择,no-resolve
  - IP-CIDR,129.134.0.0/17,🚀 节点选择,no-resolve
  - IP-CIDR,157.240.0.0/17,🚀 节点选择,no-resolve
  - IP-CIDR,173.252.64.0/18,🚀 节点选择,no-resolve
  - IP-CIDR,179.60.192.0/22,🚀 节点选择,no-resolve
  - IP-CIDR,185.60.216.0/22,🚀 节点选择,no-resolve
  - IP-CIDR,204.15.20.0/22,🚀 节点选择,no-resolve
  - DOMAIN-SUFFIX,github.com,🚀 节点选择
  - DOMAIN-SUFFIX,github.io,🚀 节点选择
  - DOMAIN-SUFFIX,githubapp.com,🚀 节点选择
  - DOMAIN-SUFFIX,githubassets.com,🚀 节点选择
  - DOMAIN-SUFFIX,githubusercontent.com,🚀 节点选择
  - DOMAIN-SUFFIX,1e100.net,🚀 节点选择
  - DOMAIN-SUFFIX,2mdn.net,🚀 节点选择
  - DOMAIN-SUFFIX,app-measurement.net,🚀 节点选择
  - DOMAIN-SUFFIX,g.co,🚀 节点选择
  - DOMAIN-SUFFIX,ggpht.com,🚀 节点选择
  - DOMAIN-SUFFIX,goo.gl,🚀 节点选择
  - DOMAIN-SUFFIX,googleapis.cn,🚀 节点选择
  - DOMAIN-SUFFIX,googleapis.com,🚀 节点选择
  - DOMAIN-SUFFIX,gstatic.cn,🚀 节点选择
  - DOMAIN-SUFFIX,gstatic.com,🚀 节点选择
  - DOMAIN-SUFFIX,gvt0.com,🚀 节点选择
  - DOMAIN-SUFFIX,gvt1.com,🚀 节点选择
  - DOMAIN-SUFFIX,gvt2.com,🚀 节点选择
  - DOMAIN-SUFFIX,gvt3.com,🚀 节点选择
  - DOMAIN-SUFFIX,xn--ngstr-lra8j.com,🚀 节点选择
  - DOMAIN-SUFFIX,youtu.be,🚀 节点选择
  - DOMAIN-SUFFIX,youtube-nocookie.com,🚀 节点选择
  - DOMAIN-SUFFIX,youtube.com,🚀 节点选择
  - DOMAIN-SUFFIX,yt.be,🚀 节点选择
  - DOMAIN-SUFFIX,ytimg.com,🚀 节点选择
  - IP-CIDR,74.125.0.0/16,🚀 节点选择,no-resolve
  - IP-CIDR,173.194.0.0/16,🚀 节点选择,no-resolve
  - IP-CIDR,120.232.181.162/32,🚀 节点选择,no-resolve
  - IP-CIDR,120.241.147.226/32,🚀 节点选择,no-resolve
  - IP-CIDR,120.253.253.226/32,🚀 节点选择,no-resolve
  - IP-CIDR,120.253.255.162/32,🚀 节点选择,no-resolve
  - IP-CIDR,120.253.255.34/32,🚀 节点选择,no-resolve
  - IP-CIDR,120.253.255.98/32,🚀 节点选择,no-resolve
  - IP-CIDR,180.163.150.162/32,🚀 节点选择,no-resolve
  - IP-CIDR,180.163.150.34/32,🚀 节点选择,no-resolve
  - IP-CIDR,180.163.151.162/32,🚀 节点选择,no-resolve
  - IP-CIDR,180.163.151.34/32,🚀 节点选择,no-resolve
  - IP-CIDR,203.208.39.0/24,🚀 节点选择,no-resolve
  - IP-CIDR,203.208.40.0/24,🚀 节点选择,no-resolve
  - IP-CIDR,203.208.41.0/24,🚀 节点选择,no-resolve
  - IP-CIDR,203.208.43.0/24,🚀 节点选择,no-resolve
  - IP-CIDR,203.208.50.0/24,🚀 节点选择,no-resolve
  - IP-CIDR,220.181.174.162/32,🚀 节点选择,no-resolve
  - IP-CIDR,220.181.174.226/32,🚀 节点选择,no-resolve
  - IP-CIDR,220.181.174.34/32,🚀 节点选择,no-resolve
  - DOMAIN-SUFFIX,cdninstagram.com,🚀 节点选择
  - DOMAIN-SUFFIX,instagram.com,🚀 节点选择
  - DOMAIN-SUFFIX,instagr.am,🚀 节点选择
  - DOMAIN-SUFFIX,kakao.com,🚀 节点选择
  - DOMAIN-SUFFIX,kakao.co.kr,🚀 节点选择
  - DOMAIN-SUFFIX,kakaocdn.net,🚀 节点选择
  - IP-CIDR,1.201.0.0/24,🚀 节点选择,no-resolve
  - IP-CIDR,27.0.236.0/22,🚀 节点选择,no-resolve
  - IP-CIDR,103.27.148.0/22,🚀 节点选择,no-resolve
  - IP-CIDR,103.246.56.0/22,🚀 节点选择,no-resolve
  - IP-CIDR,110.76.140.0/22,🚀 节点选择,no-resolve
  - IP-CIDR,113.61.104.0/22,🚀 节点选择,no-resolve
  - DOMAIN-SUFFIX,lin.ee,🚀 节点选择
  - DOMAIN-SUFFIX,line-apps.com,🚀 节点选择
  - DOMAIN-SUFFIX,line-cdn.net,🚀 节点选择
  - DOMAIN-SUFFIX,line-scdn.net,🚀 节点选择
  - DOMAIN-SUFFIX,line.me,🚀 节点选择
  - DOMAIN-SUFFIX,line.naver.jp,🚀 节点选择
  - DOMAIN-SUFFIX,nhncorp.jp,🚀 节点选择
  - IP-CIDR,103.2.28.0/24,🚀 节点选择,no-resolve
  - IP-CIDR,103.2.30.0/23,🚀 节点选择,no-resolve
  - IP-CIDR,119.235.224.0/24,🚀 节点选择,no-resolve
  - IP-CIDR,119.235.232.0/24,🚀 节点选择,no-resolve
  - IP-CIDR,119.235.235.0/24,🚀 节点选择,no-resolve
  - IP-CIDR,119.235.236.0/23,🚀 节点选择,no-resolve
  - IP-CIDR,147.92.128.0/17,🚀 节点选择,no-resolve
  - IP-CIDR,203.104.128.0/19,🚀 节点选择,no-resolve
  - DOMAIN-SUFFIX,openai.com,🚀 节点选择
  - DOMAIN-SUFFIX,challenges.cloudflare.com,🚀 节点选择
  - DOMAIN-SUFFIX,ai.com,🚀 节点选择
  - DOMAIN-KEYWORD,1drv,🚀 节点选择
  - DOMAIN-KEYWORD,onedrive,🚀 节点选择
  - DOMAIN-KEYWORD,skydrive,🚀 节点选择
  - DOMAIN-SUFFIX,livefilestore.com,🚀 节点选择
  - DOMAIN-SUFFIX,oneclient.sfx.ms,🚀 节点选择
  - DOMAIN-SUFFIX,onedrive.com,🚀 节点选择
  - DOMAIN-SUFFIX,onedrive.live.com,🚀 节点选择
  - DOMAIN-SUFFIX,photos.live.com,🚀 节点选择
  - DOMAIN-SUFFIX,skydrive.wns.windows.com,🚀 节点选择
  - DOMAIN-SUFFIX,spoprod-a.akamaihd.net,🚀 节点选择
  - DOMAIN-SUFFIX,storage.live.com,🚀 节点选择
  - DOMAIN-SUFFIX,storage.msn.com,🚀 节点选择
  - DOMAIN-KEYWORD,porn,🚀 节点选择
  - DOMAIN-SUFFIX,8teenxxx.com,🚀 节点选择
  - DOMAIN-SUFFIX,ahcdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,bcvcdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,bongacams.com,🚀 节点选择
  - DOMAIN-SUFFIX,chaturbate.com,🚀 节点选择
  - DOMAIN-SUFFIX,dditscdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,livejasmin.com,🚀 节点选择
  - DOMAIN-SUFFIX,phncdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,phprcdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,pornhub.com,🚀 节点选择
  - DOMAIN-SUFFIX,pornhubpremium.com,🚀 节点选择
  - DOMAIN-SUFFIX,rdtcdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,redtube.com,🚀 节点选择
  - DOMAIN-SUFFIX,sb-cd.com,🚀 节点选择
  - DOMAIN-SUFFIX,spankbang.com,🚀 节点选择
  - DOMAIN-SUFFIX,t66y.com,🚀 节点选择
  - DOMAIN-SUFFIX,xhamster.com,🚀 节点选择
  - DOMAIN-SUFFIX,xnxx-cdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,xnxx.com,🚀 节点选择
  - DOMAIN-SUFFIX,xvideos-cdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,xvideos.com,🚀 节点选择
  - DOMAIN-SUFFIX,ypncdn.com,🚀 节点选择
  - DOMAIN-SUFFIX,pixiv.net,🚀 节点选择
  - DOMAIN-SUFFIX,pximg.net,🚀 节点选择
  - DOMAIN-SUFFIX,amplitude.com,🚀 节点选择
  - DOMAIN-SUFFIX,firebaseio.com,🚀 节点选择
  - DOMAIN-SUFFIX,hockeyapp.net,🚀 节点选择
  - DOMAIN-SUFFIX,readdle.com,🚀 节点选择
  - DOMAIN-SUFFIX,smartmailcloud.com,🚀 节点选择
  - DOMAIN-SUFFIX,fanatical.com,🚀 节点选择
  - DOMAIN-SUFFIX,humblebundle.com,🚀 节点选择
  - DOMAIN-SUFFIX,underlords.com,🚀 节点选择
  - DOMAIN-SUFFIX,valvesoftware.com,🚀 节点选择
  - DOMAIN-SUFFIX,playartifact.com,🚀 节点选择
  - DOMAIN-SUFFIX,steam-chat.com,🚀 节点选择
  - DOMAIN-SUFFIX,steamcommunity.com,🚀 节点选择
  - DOMAIN-SUFFIX,steamgames.com,🚀 节点选择
  - DOMAIN-SUFFIX,steampowered.com,🚀 节点选择
  - DOMAIN-SUFFIX,steamserver.net,🚀 节点选择
  - DOMAIN-SUFFIX,steamstatic.com,🚀 节点选择
  - DOMAIN-SUFFIX,steamstat.us,🚀 节点选择
  - DOMAIN,steambroadcast.akamaized.net,🚀 节点选择
  - DOMAIN,steamcommunity-a.akamaihd.net,🚀 节点选择
  - DOMAIN,steamstore-a.akamaihd.net,🚀 节点选择
  - DOMAIN,steamusercontent-a.akamaihd.net,🚀 节点选择
  - DOMAIN,steamuserimages-a.akamaihd.net,🚀 节点选择
  - DOMAIN,steampipe.akamaized.net,🚀 节点选择
  - DOMAIN-SUFFIX,tap.io,🚀 节点选择
  - DOMAIN-SUFFIX,taptap.tw,🚀 节点选择
  - DOMAIN-SUFFIX,twitch.tv,🚀 节点选择
  - DOMAIN-SUFFIX,ttvnw.net,🚀 节点选择
  - DOMAIN-SUFFIX,jtvnw.net,🚀 节点选择
  - DOMAIN-KEYWORD,ttvnw,🚀 节点选择
  - DOMAIN-SUFFIX,t.co,🚀 节点选择
  - DOMAIN-SUFFIX,twimg.co,🚀 节点选择
  - DOMAIN-SUFFIX,twimg.com,🚀 节点选择
  - DOMAIN-SUFFIX,twimg.org,🚀 节点选择
  - DOMAIN-SUFFIX,t.me,🚀 节点选择
  - DOMAIN-SUFFIX,tdesktop.com,🚀 节点选择
  - DOMAIN-SUFFIX,telegra.ph,🚀 节点选择
  - DOMAIN-SUFFIX,telegram.me,🚀 节点选择
  - DOMAIN-SUFFIX,telegram.org,🚀 节点选择
  - DOMAIN-SUFFIX,telesco.pe,🚀 节点选择
  - IP-CIDR,91.108.0.0/16,🚀 节点选择,no-resolve
  - IP-CIDR,109.239.140.0/24,🚀 节点选择,no-resolve
  - IP-CIDR,149.154.160.0/20,🚀 节点选择,no-resolve
  - IP-CIDR6,2001:67c:4e8::/48,🚀 节点选择,no-resolve
  - IP-CIDR6,2001:b28:f23d::/48,🚀 节点选择,no-resolve
  - IP-CIDR6,2001:b28:f23f::/48,🚀 节点选择,no-resolve
  - DOMAIN-SUFFIX,terabox.com,🚀 节点选择
  - DOMAIN-SUFFIX,teraboxcdn.com,🚀 节点选择
  - IP-CIDR,18.194.0.0/15,🚀 节点选择,no-resolve
  - IP-CIDR,34.224.0.0/12,🚀 节点选择,no-resolve
  - IP-CIDR,54.242.0.0/15,🚀 节点选择,no-resolve
  - IP-CIDR,50.22.198.204/30,🚀 节点选择,no-resolve
  - IP-CIDR,208.43.122.128/27,🚀 节点选择,no-resolve
  - IP-CIDR,108.168.174.0/16,🚀 节点选择,no-resolve
  - IP-CIDR,173.192.231.32/27,🚀 节点选择,no-resolve
  - IP-CIDR,158.85.5.192/27,🚀 节点选择,no-resolve
  - IP-CIDR,174.37.243.0/16,🚀 节点选择,no-resolve
  - IP-CIDR,158.85.46.128/27,🚀 节点选择,no-resolve
  - IP-CIDR,173.192.222.160/27,🚀 节点选择,no-resolve
  - IP-CIDR,184.173.128.0/17,🚀 节点选择,no-resolve
  - IP-CIDR,158.85.224.160/27,🚀 节点选择,no-resolve
  - IP-CIDR,75.126.150.0/16,🚀 节点选择,no-resolve
  - IP-CIDR,69.171.235.0/16,🚀 节点选择,no-resolve
  - DOMAIN-SUFFIX,mediawiki.org,🚀 节点选择
  - DOMAIN-SUFFIX,wikibooks.org,🚀 节点选择
  - DOMAIN-SUFFIX,wikidata.org,🚀 节点选择
  - DOMAIN-SUFFIX,wikileaks.org,🚀 节点选择
  - DOMAIN-SUFFIX,wikimedia.org,🚀 节点选择
  - DOMAIN-SUFFIX,wikinews.org,🚀 节点选择
  - DOMAIN-SUFFIX,wikipedia.org,🚀 节点选择
  - DOMAIN-SUFFIX,wikiquote.org,🚀 节点选择
  - DOMAIN-SUFFIX,wikisource.org,🚀 节点选择
  - DOMAIN-SUFFIX,wikiversity.org,🚀 节点选择
  - DOMAIN-SUFFIX,wikivoyage.org,🚀 节点选择
  - DOMAIN-SUFFIX,wiktionary.org,🚀 节点选择
  - DOMAIN-SUFFIX,neulion.com,🚀 节点选择
  - DOMAIN-SUFFIX,icntv.xyz,🚀 节点选择
  - DOMAIN-SUFFIX,flzbcdn.xyz,🚀 节点选择
  - DOMAIN-SUFFIX,ocnttv.com,🚀 节点选择
  - DOMAIN-SUFFIX,vikacg.com,🚀 节点选择
  - DOMAIN-SUFFIX,picjs.xyz,🚀 节点选择
  - DOMAIN-SUFFIX,13th.tech,🎯 全球直连
  - DOMAIN-SUFFIX,423down.com,🎯 全球直连
  - DOMAIN-SUFFIX,bokecc.com,🎯 全球直连
  - DOMAIN-SUFFIX,chaipip.com,🎯 全球直连
  - DOMAIN-SUFFIX,chinaplay.store,🎯 全球直连
  - DOMAIN-SUFFIX,hrtsea.com,🎯 全球直连
  - DOMAIN-SUFFIX,kaikeba.com,🎯 全球直连
  - DOMAIN-SUFFIX,laomo.me,🎯 全球直连
  - DOMAIN-SUFFIX,mpyit.com,🎯 全球直连
  - DOMAIN-SUFFIX,msftconnecttest.com,🎯 全球直连
  - DOMAIN-SUFFIX,msftncsi.com,🎯 全球直连
  - DOMAIN-SUFFIX,qupu123.com,🎯 全球直连
  - DOMAIN-SUFFIX,pdfwifi.com,🎯 全球直连
  - DOMAIN-SUFFIX,zhenguanyu.biz,🎯 全球直连
  - DOMAIN-SUFFIX,zhenguanyu.com,🎯 全球直连
  - DOMAIN-SUFFIX,cn,🎯 全球直连
  - DOMAIN-SUFFIX,xn--fiqs8s,🎯 全球直连
  - DOMAIN-SUFFIX,xn--55qx5d,🎯 全球直连
  - DOMAIN-SUFFIX,xn--io0a7i,🎯 全球直连
  - DOMAIN-KEYWORD,360buy,🎯 全球直连
  - DOMAIN-KEYWORD,alicdn,🎯 全球直连
  - DOMAIN-KEYWORD,alimama,🎯 全球直连
  - DOMAIN-KEYWORD,alipay,🎯 全球直连
  - DOMAIN-KEYWORD,appzapp,🎯 全球直连
  - DOMAIN-KEYWORD,baidupcs,🎯 全球直连
  - DOMAIN-KEYWORD,bilibili,🎯 全球直连
  - DOMAIN-KEYWORD,ccgslb,🎯 全球直连
  - DOMAIN-KEYWORD,chinacache,🎯 全球直连
  - DOMAIN-KEYWORD,duobao,🎯 全球直连
  - DOMAIN-KEYWORD,jdpay,🎯 全球直连
  - DOMAIN-KEYWORD,moke,🎯 全球直连
  - DOMAIN-KEYWORD,qhimg,🎯 全球直连
  - DOMAIN-KEYWORD,vpimg,🎯 全球直连
  - DOMAIN-KEYWORD,xiami,🎯 全球直连
  - DOMAIN-KEYWORD,xiaomi,🎯 全球直连
  - DOMAIN-SUFFIX,360.com,🎯 全球直连
  - DOMAIN-SUFFIX,360kuai.com,🎯 全球直连
  - DOMAIN-SUFFIX,360safe.com,🎯 全球直连
  - DOMAIN-SUFFIX,dhrest.com,🎯 全球直连
  - DOMAIN-SUFFIX,qhres.com,🎯 全球直连
  - DOMAIN-SUFFIX,qhstatic.com,🎯 全球直连
  - DOMAIN-SUFFIX,qhupdate.com,🎯 全球直连
  - DOMAIN-SUFFIX,so.com,🎯 全球直连
  - DOMAIN-SUFFIX,4399.com,🎯 全球直连
  - DOMAIN-SUFFIX,4399pk.com,🎯 全球直连
  - DOMAIN-SUFFIX,5054399.com,🎯 全球直连
  - DOMAIN-SUFFIX,img4399.com,🎯 全球直连
  - DOMAIN-SUFFIX,58.com,🎯 全球直连
  - DOMAIN-SUFFIX,1688.com,🎯 全球直连
  - DOMAIN-SUFFIX,aliapp.org,🎯 全球直连
  - DOMAIN-SUFFIX,alibaba.com,🎯 全球直连
  - DOMAIN-SUFFIX,alibabacloud.com,🎯 全球直连
  - DOMAIN-SUFFIX,alibabausercontent.com,🎯 全球直连
  - DOMAIN-SUFFIX,alicdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,alicloudccp.com,🎯 全球直连
  - DOMAIN-SUFFIX,aliexpress.com,🎯 全球直连
  - DOMAIN-SUFFIX,aliimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,alikunlun.com,🎯 全球直连
  - DOMAIN-SUFFIX,alipay.com,🎯 全球直连
  - DOMAIN-SUFFIX,alipayobjects.com,🎯 全球直连
  - DOMAIN-SUFFIX,alisoft.com,🎯 全球直连
  - DOMAIN-SUFFIX,aliyun.com,🎯 全球直连
  - DOMAIN-SUFFIX,aliyuncdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,aliyuncs.com,🎯 全球直连
  - DOMAIN-SUFFIX,aliyundrive.com,🎯 全球直连
  - DOMAIN-SUFFIX,amap.com,🎯 全球直连
  - DOMAIN-SUFFIX,autonavi.com,🎯 全球直连
  - DOMAIN-SUFFIX,dingtalk.com,🎯 全球直连
  - DOMAIN-SUFFIX,ele.me,🎯 全球直连
  - DOMAIN-SUFFIX,hichina.com,🎯 全球直连
  - DOMAIN-SUFFIX,mmstat.com,🎯 全球直连
  - DOMAIN-SUFFIX,mxhichina.com,🎯 全球直连
  - DOMAIN-SUFFIX,soku.com,🎯 全球直连
  - DOMAIN-SUFFIX,taobao.com,🎯 全球直连
  - DOMAIN-SUFFIX,taobaocdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,tbcache.com,🎯 全球直连
  - DOMAIN-SUFFIX,tbcdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,tmall.com,🎯 全球直连
  - DOMAIN-SUFFIX,tmall.hk,🎯 全球直连
  - DOMAIN-SUFFIX,ucweb.com,🎯 全球直连
  - DOMAIN-SUFFIX,xiami.com,🎯 全球直连
  - DOMAIN-SUFFIX,xiami.net,🎯 全球直连
  - DOMAIN-SUFFIX,ykimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,youku.com,🎯 全球直连
  - DOMAIN-SUFFIX,baidu.com,🎯 全球直连
  - DOMAIN-SUFFIX,baidubcr.com,🎯 全球直连
  - DOMAIN-SUFFIX,baidupcs.com,🎯 全球直连
  - DOMAIN-SUFFIX,baidustatic.com,🎯 全球直连
  - DOMAIN-SUFFIX,bcebos.com,🎯 全球直连
  - DOMAIN-SUFFIX,bdimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,bdstatic.com,🎯 全球直连
  - DOMAIN-SUFFIX,bdurl.net,🎯 全球直连
  - DOMAIN-SUFFIX,hao123.com,🎯 全球直连
  - DOMAIN-SUFFIX,hao123img.com,🎯 全球直连
  - DOMAIN-SUFFIX,jomodns.com,🎯 全球直连
  - DOMAIN-SUFFIX,yunjiasu-cdn.net,🎯 全球直连
  - DOMAIN-SUFFIX,acg.tv,🎯 全球直连
  - DOMAIN-SUFFIX,acgvideo.com,🎯 全球直连
  - DOMAIN-SUFFIX,b23.tv,🎯 全球直连
  - DOMAIN-SUFFIX,bigfun.cn,🎯 全球直连
  - DOMAIN-SUFFIX,bigfunapp.cn,🎯 全球直连
  - DOMAIN-SUFFIX,biliapi.com,🎯 全球直连
  - DOMAIN-SUFFIX,biliapi.net,🎯 全球直连
  - DOMAIN-SUFFIX,bilibili.com,🎯 全球直连
  - DOMAIN-SUFFIX,biligame.com,🎯 全球直连
  - DOMAIN-SUFFIX,biligame.net,🎯 全球直连
  - DOMAIN-SUFFIX,bilivideo.com,🎯 全球直连
  - DOMAIN-SUFFIX,bilivideo.cn,🎯 全球直连
  - DOMAIN-SUFFIX,hdslb.com,🎯 全球直连
  - DOMAIN-SUFFIX,im9.com,🎯 全球直连
  - DOMAIN-SUFFIX,smtcdns.net,🎯 全球直连
  - DOMAIN-SUFFIX,battle.net,🎯 全球直连
  - DOMAIN-SUFFIX,battlenet.com,🎯 全球直连
  - DOMAIN-SUFFIX,blizzard.com,🎯 全球直连
  - DOMAIN-SUFFIX,amemv.com,🎯 全球直连
  - DOMAIN-SUFFIX,bdxiguaimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,bdxiguastatic.com,🎯 全球直连
  - DOMAIN-SUFFIX,byted-static.com,🎯 全球直连
  - DOMAIN-SUFFIX,bytedance.com,🎯 全球直连
  - DOMAIN-SUFFIX,bytedance.net,🎯 全球直连
  - DOMAIN-SUFFIX,bytedns.net,🎯 全球直连
  - DOMAIN-SUFFIX,bytednsdoc.com,🎯 全球直连
  - DOMAIN-SUFFIX,bytegoofy.com,🎯 全球直连
  - DOMAIN-SUFFIX,byteimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,bytescm.com,🎯 全球直连
  - DOMAIN-SUFFIX,bytetos.com,🎯 全球直连
  - DOMAIN-SUFFIX,bytexservice.com,🎯 全球直连
  - DOMAIN-SUFFIX,douyin.com,🎯 全球直连
  - DOMAIN-SUFFIX,douyincdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,douyinpic.com,🎯 全球直连
  - DOMAIN-SUFFIX,douyinstatic.com,🎯 全球直连
  - DOMAIN-SUFFIX,douyinvod.com,🎯 全球直连
  - DOMAIN-SUFFIX,feelgood.cn,🎯 全球直连
  - DOMAIN-SUFFIX,feiliao.com,🎯 全球直连
  - DOMAIN-SUFFIX,gifshow.com,🎯 全球直连
  - DOMAIN-SUFFIX,huoshan.com,🎯 全球直连
  - DOMAIN-SUFFIX,huoshanzhibo.com,🎯 全球直连
  - DOMAIN-SUFFIX,ibytedapm.com,🎯 全球直连
  - DOMAIN-SUFFIX,iesdouyin.com,🎯 全球直连
  - DOMAIN-SUFFIX,ixigua.com,🎯 全球直连
  - DOMAIN-SUFFIX,kspkg.com,🎯 全球直连
  - DOMAIN-SUFFIX,pstatp.com,🎯 全球直连
  - DOMAIN-SUFFIX,snssdk.com,🎯 全球直连
  - DOMAIN-SUFFIX,toutiao.com,🎯 全球直连
  - DOMAIN-SUFFIX,toutiao13.com,🎯 全球直连
  - DOMAIN-SUFFIX,toutiaoapi.com,🎯 全球直连
  - DOMAIN-SUFFIX,toutiaocdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,toutiaocdn.net,🎯 全球直连
  - DOMAIN-SUFFIX,toutiaocloud.com,🎯 全球直连
  - DOMAIN-SUFFIX,toutiaohao.com,🎯 全球直连
  - DOMAIN-SUFFIX,toutiaohao.net,🎯 全球直连
  - DOMAIN-SUFFIX,toutiaoimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,toutiaopage.com,🎯 全球直连
  - DOMAIN-SUFFIX,wukong.com,🎯 全球直连
  - DOMAIN-SUFFIX,zijieapi.com,🎯 全球直连
  - DOMAIN-SUFFIX,zijieimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,zjbyte.com,🎯 全球直连
  - DOMAIN-SUFFIX,zjcdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,cctv.com,🎯 全球直连
  - DOMAIN-SUFFIX,cctvpic.com,🎯 全球直连
  - DOMAIN-SUFFIX,livechina.com,🎯 全球直连
  - DOMAIN-SUFFIX,21cn.com,🎯 全球直连
  - DOMAIN-SUFFIX,didialift.com,🎯 全球直连
  - DOMAIN-SUFFIX,didiglobal.com,🎯 全球直连
  - DOMAIN-SUFFIX,udache.com,🎯 全球直连
  - DOMAIN-SUFFIX,douyu.com,🎯 全球直连
  - DOMAIN-SUFFIX,douyu.tv,🎯 全球直连
  - DOMAIN-SUFFIX,douyuscdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,douyutv.com,🎯 全球直连
  - DOMAIN-SUFFIX,epicgames.com,🎯 全球直连
  - DOMAIN-SUFFIX,epicgames.dev,🎯 全球直连
  - DOMAIN-SUFFIX,helpshift.com,🎯 全球直连
  - DOMAIN-SUFFIX,paragon.com,🎯 全球直连
  - DOMAIN-SUFFIX,unrealengine.com,🎯 全球直连
  - DOMAIN-SUFFIX,dbankcdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,hc-cdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,hicloud.com,🎯 全球直连
  - DOMAIN-SUFFIX,hihonor.com,🎯 全球直连
  - DOMAIN-SUFFIX,huawei.com,🎯 全球直连
  - DOMAIN-SUFFIX,huaweicloud.com,🎯 全球直连
  - DOMAIN-SUFFIX,huaweishop.net,🎯 全球直连
  - DOMAIN-SUFFIX,hwccpc.com,🎯 全球直连
  - DOMAIN-SUFFIX,vmall.com,🎯 全球直连
  - DOMAIN-SUFFIX,vmallres.com,🎯 全球直连
  - DOMAIN-SUFFIX,iflyink.com,🎯 全球直连
  - DOMAIN-SUFFIX,iflyrec.com,🎯 全球直连
  - DOMAIN-SUFFIX,iflytek.com,🎯 全球直连
  - DOMAIN-SUFFIX,71.am,🎯 全球直连
  - DOMAIN-SUFFIX,71edge.com,🎯 全球直连
  - DOMAIN-SUFFIX,iqiyi.com,🎯 全球直连
  - DOMAIN-SUFFIX,iqiyipic.com,🎯 全球直连
  - DOMAIN-SUFFIX,ppsimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,qiyi.com,🎯 全球直连
  - DOMAIN-SUFFIX,qiyipic.com,🎯 全球直连
  - DOMAIN-SUFFIX,qy.net,🎯 全球直连
  - DOMAIN-SUFFIX,360buy.com,🎯 全球直连
  - DOMAIN-SUFFIX,360buyimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,jcloudcs.com,🎯 全球直连
  - DOMAIN-SUFFIX,jd.com,🎯 全球直连
  - DOMAIN-SUFFIX,jd.hk,🎯 全球直连
  - DOMAIN-SUFFIX,jdcloud.com,🎯 全球直连
  - DOMAIN-SUFFIX,jdpay.com,🎯 全球直连
  - DOMAIN-SUFFIX,paipai.com,🎯 全球直连
  - DOMAIN-SUFFIX,iciba.com,🎯 全球直连
  - DOMAIN-SUFFIX,ksosoft.com,🎯 全球直连
  - DOMAIN-SUFFIX,ksyun.com,🎯 全球直连
  - DOMAIN-SUFFIX,kuaishou.com,🎯 全球直连
  - DOMAIN-SUFFIX,yximgs.com,🎯 全球直连
  - DOMAIN-SUFFIX,meitu.com,🎯 全球直连
  - DOMAIN-SUFFIX,meitudata.com,🎯 全球直连
  - DOMAIN-SUFFIX,meitustat.com,🎯 全球直连
  - DOMAIN-SUFFIX,meipai.com,🎯 全球直连
  - DOMAIN-SUFFIX,le.com,🎯 全球直连
  - DOMAIN-SUFFIX,lecloud.com,🎯 全球直连
  - DOMAIN-SUFFIX,letv.com,🎯 全球直连
  - DOMAIN-SUFFIX,letvcloud.com,🎯 全球直连
  - DOMAIN-SUFFIX,letvimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,letvlive.com,🎯 全球直连
  - DOMAIN-SUFFIX,letvstore.com,🎯 全球直连
  - DOMAIN-SUFFIX,hitv.com,🎯 全球直连
  - DOMAIN-SUFFIX,hunantv.com,🎯 全球直连
  - DOMAIN-SUFFIX,mgtv.com,🎯 全球直连
  - DOMAIN-SUFFIX,duokan.com,🎯 全球直连
  - DOMAIN-SUFFIX,mi-img.com,🎯 全球直连
  - DOMAIN-SUFFIX,mi.com,🎯 全球直连
  - DOMAIN-SUFFIX,miui.com,🎯 全球直连
  - DOMAIN-SUFFIX,xiaomi.com,🎯 全球直连
  - DOMAIN-SUFFIX,xiaomi.net,🎯 全球直连
  - DOMAIN-SUFFIX,xiaomicp.com,🎯 全球直连
  - DOMAIN-SUFFIX,126.com,🎯 全球直连
  - DOMAIN-SUFFIX,126.net,🎯 全球直连
  - DOMAIN-SUFFIX,127.net,🎯 全球直连
  - DOMAIN-SUFFIX,163.com,🎯 全球直连
  - DOMAIN-SUFFIX,163yun.com,🎯 全球直连
  - DOMAIN-SUFFIX,lofter.com,🎯 全球直连
  - DOMAIN-SUFFIX,netease.com,🎯 全球直连
  - DOMAIN-SUFFIX,ydstatic.com,🎯 全球直连
  - DOMAIN-SUFFIX,youdao.com,🎯 全球直连
  - DOMAIN-SUFFIX,pplive.com,🎯 全球直连
  - DOMAIN-SUFFIX,pptv.com,🎯 全球直连
  - DOMAIN-SUFFIX,pinduoduo.com,🎯 全球直连
  - DOMAIN-SUFFIX,yangkeduo.com,🎯 全球直连
  - DOMAIN-SUFFIX,leju.com,🎯 全球直连
  - DOMAIN-SUFFIX,miaopai.com,🎯 全球直连
  - DOMAIN-SUFFIX,sina.com,🎯 全球直连
  - DOMAIN-SUFFIX,sina.com.cn,🎯 全球直连
  - DOMAIN-SUFFIX,sina.cn,🎯 全球直连
  - DOMAIN-SUFFIX,sinaapp.com,🎯 全球直连
  - DOMAIN-SUFFIX,sinaapp.cn,🎯 全球直连
  - DOMAIN-SUFFIX,sinaimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,sinaimg.cn,🎯 全球直连
  - DOMAIN-SUFFIX,weibo.com,🎯 全球直连
  - DOMAIN-SUFFIX,weibo.cn,🎯 全球直连
  - DOMAIN-SUFFIX,weibocdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,weibocdn.cn,🎯 全球直连
  - DOMAIN-SUFFIX,xiaoka.tv,🎯 全球直连
  - DOMAIN-SUFFIX,go2map.com,🎯 全球直连
  - DOMAIN-SUFFIX,sogo.com,🎯 全球直连
  - DOMAIN-SUFFIX,sogou.com,🎯 全球直连
  - DOMAIN-SUFFIX,sogoucdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,sohu-inc.com,🎯 全球直连
  - DOMAIN-SUFFIX,sohu.com,🎯 全球直连
  - DOMAIN-SUFFIX,sohucs.com,🎯 全球直连
  - DOMAIN-SUFFIX,sohuno.com,🎯 全球直连
  - DOMAIN-SUFFIX,sohurdc.com,🎯 全球直连
  - DOMAIN-SUFFIX,v-56.com,🎯 全球直连
  - DOMAIN-SUFFIX,playstation.com,🎯 全球直连
  - DOMAIN-SUFFIX,playstation.net,🎯 全球直连
  - DOMAIN-SUFFIX,playstationnetwork.com,🎯 全球直连
  - DOMAIN-SUFFIX,sony.com,🎯 全球直连
  - DOMAIN-SUFFIX,sonyentertainmentnetwork.com,🎯 全球直连
  - DOMAIN-SUFFIX,cm.steampowered.com,🎯 全球直连
  - DOMAIN-SUFFIX,steamcontent.com,🎯 全球直连
  - DOMAIN-SUFFIX,steamusercontent.com,🎯 全球直连
  - DOMAIN-SUFFIX,steamchina.com,🎯 全球直连
  - DOMAIN,csgo.wmsj.cn,🎯 全球直连
  - DOMAIN,dota2.wmsj.cn,🎯 全球直连
  - DOMAIN,wmsjsteam.com,🎯 全球直连
  - DOMAIN,dl.steam.clngaa.com,🎯 全球直连
  - DOMAIN,dl.steam.ksyna.com,🎯 全球直连
  - DOMAIN,st.dl.bscstorage.net,🎯 全球直连
  - DOMAIN,st.dl.eccdnx.com,🎯 全球直连
  - DOMAIN,st.dl.pinyuncloud.com,🎯 全球直连
  - DOMAIN,xz.pphimalayanrt.com,🎯 全球直连
  - DOMAIN,steampipe.steamcontent.tnkjmec.com,🎯 全球直连
  - DOMAIN,steampowered.com.8686c.com,🎯 全球直连
  - DOMAIN,steamstatic.com.8686c.com,🎯 全球直连
  - DOMAIN-SUFFIX,foxmail.com,🎯 全球直连
  - DOMAIN-SUFFIX,gtimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,idqqimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,igamecj.com,🎯 全球直连
  - DOMAIN-SUFFIX,myapp.com,🎯 全球直连
  - DOMAIN-SUFFIX,myqcloud.com,🎯 全球直连
  - DOMAIN-SUFFIX,qq.com,🎯 全球直连
  - DOMAIN-SUFFIX,qqmail.com,🎯 全球直连
  - DOMAIN-SUFFIX,qqurl.com,🎯 全球直连
  - DOMAIN-SUFFIX,smtcdns.com,🎯 全球直连
  - DOMAIN-SUFFIX,smtcdns.net,🎯 全球直连
  - DOMAIN-SUFFIX,soso.com,🎯 全球直连
  - DOMAIN-SUFFIX,tencent-cloud.net,🎯 全球直连
  - DOMAIN-SUFFIX,tencent.com,🎯 全球直连
  - DOMAIN-SUFFIX,tencentmind.com,🎯 全球直连
  - DOMAIN-SUFFIX,tenpay.com,🎯 全球直连
  - DOMAIN-SUFFIX,wechat.com,🎯 全球直连
  - DOMAIN-SUFFIX,weixin.com,🎯 全球直连
  - DOMAIN-SUFFIX,weiyun.com,🎯 全球直连
  - DOMAIN-SUFFIX,appsimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,appvipshop.com,🎯 全球直连
  - DOMAIN-SUFFIX,vip.com,🎯 全球直连
  - DOMAIN-SUFFIX,vipstatic.com,🎯 全球直连
  - DOMAIN-SUFFIX,ximalaya.com,🎯 全球直连
  - DOMAIN-SUFFIX,xmcdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,00cdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,88cdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,kanimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,kankan.com,🎯 全球直连
  - DOMAIN-SUFFIX,p2cdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,sandai.net,🎯 全球直连
  - DOMAIN-SUFFIX,thundercdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,xunlei.com,🎯 全球直连
  - DOMAIN-SUFFIX,got001.com,🎯 全球直连
  - DOMAIN-SUFFIX,p4pfile.com,🎯 全球直连
  - DOMAIN-SUFFIX,rrys.tv,🎯 全球直连
  - DOMAIN-SUFFIX,rrys2020.com,🎯 全球直连
  - DOMAIN-SUFFIX,yyets.com,🎯 全球直连
  - DOMAIN-SUFFIX,zimuzu.io,🎯 全球直连
  - DOMAIN-SUFFIX,zimuzu.tv,🎯 全球直连
  - DOMAIN-SUFFIX,zmz001.com,🎯 全球直连
  - DOMAIN-SUFFIX,zmz002.com,🎯 全球直连
  - DOMAIN-SUFFIX,zmz003.com,🎯 全球直连
  - DOMAIN-SUFFIX,zmz004.com,🎯 全球直连
  - DOMAIN-SUFFIX,zmz2019.com,🎯 全球直连
  - DOMAIN-SUFFIX,zmzapi.com,🎯 全球直连
  - DOMAIN-SUFFIX,zmzapi.net,🎯 全球直连
  - DOMAIN-SUFFIX,zmzfile.com,🎯 全球直连
  - DOMAIN-KEYWORD,announce,🎯 全球直连
  - DOMAIN-KEYWORD,torrent,🎯 全球直连
  - DOMAIN-KEYWORD,tracker,🎯 全球直连
  - DOMAIN-KEYWORD,announce,🎯 全球直连
  - DOMAIN-KEYWORD,torrent,🎯 全球直连
  - DOMAIN-KEYWORD,tracker,🎯 全球直连
  - DOMAIN-SUFFIX,52pt.site,🎯 全球直连
  - DOMAIN-SUFFIX,aidoru-online.me,🎯 全球直连
  - DOMAIN-SUFFIX,alpharatio.cc,🎯 全球直连
  - DOMAIN-SUFFIX,animebytes.tv,🎯 全球直连
  - DOMAIN-SUFFIX,animetorrents.me,🎯 全球直连
  - DOMAIN-SUFFIX,anthelion.me,🎯 全球直连
  - DOMAIN-SUFFIX,asiancinema.me,🎯 全球直连
  - DOMAIN-SUFFIX,audiences.me,🎯 全球直连
  - DOMAIN-SUFFIX,avgv.cc,🎯 全球直连
  - DOMAIN-SUFFIX,avistaz.to,🎯 全球直连
  - DOMAIN-SUFFIX,awesome-hd.me,🎯 全球直连
  - DOMAIN-SUFFIX,beitai.pt,🎯 全球直连
  - DOMAIN-SUFFIX,beyond-hd.me,🎯 全球直连
  - DOMAIN-SUFFIX,bibliotik.me,🎯 全球直连
  - DOMAIN-SUFFIX,bittorrent.com,🎯 全球直连
  - DOMAIN-SUFFIX,blutopia.xyz,🎯 全球直连
  - DOMAIN-SUFFIX,broadcasthe.net,🎯 全球直连
  - DOMAIN-SUFFIX,bt.byr.cn,🎯 全球直连
  - DOMAIN-SUFFIX,bt.neu6.edu.cn,🎯 全球直连
  - DOMAIN-SUFFIX,btschool.club,🎯 全球直连
  - DOMAIN-SUFFIX,bwtorrents.tv,🎯 全球直连
  - DOMAIN-SUFFIX,byr.pt,🎯 全球直连
  - DOMAIN-SUFFIX,ccfbits.org,🎯 全球直连
  - DOMAIN-SUFFIX,cgpeers.com,🎯 全球直连
  - DOMAIN-SUFFIX,chdbits.co,🎯 全球直连
  - DOMAIN-SUFFIX,cinemageddon.net,🎯 全球直连
  - DOMAIN-SUFFIX,cinematik.net,🎯 全球直连
  - DOMAIN-SUFFIX,cinemaz.to,🎯 全球直连
  - DOMAIN-SUFFIX,classix-unlimited.co.uk,🎯 全球直连
  - DOMAIN-SUFFIX,concertos.live,🎯 全球直连
  - DOMAIN-SUFFIX,dicmusic.club,🎯 全球直连
  - DOMAIN-SUFFIX,discfan.net,🎯 全球直连
  - DOMAIN-SUFFIX,dxdhd.com,🎯 全球直连
  - DOMAIN-SUFFIX,eastgame.org,🎯 全球直连
  - DOMAIN-SUFFIX,empornium.me,🎯 全球直连
  - DOMAIN-SUFFIX,et8.org,🎯 全球直连
  - DOMAIN-SUFFIX,exoticaz.to,🎯 全球直连
  - DOMAIN-SUFFIX,extremlymtorrents.ws,🎯 全球直连
  - DOMAIN-SUFFIX,filelist.io,🎯 全球直连
  - DOMAIN-SUFFIX,gainbound.net,🎯 全球直连
  - DOMAIN-SUFFIX,gazellegames.net,🎯 全球直连
  - DOMAIN-SUFFIX,gfxpeers.net,🎯 全球直连
  - DOMAIN-SUFFIX,hd-space.org,🎯 全球直连
  - DOMAIN-SUFFIX,hd-torrents.org,🎯 全球直连
  - DOMAIN-SUFFIX,hd4.xyz,🎯 全球直连
  - DOMAIN-SUFFIX,hd4fans.org,🎯 全球直连
  - DOMAIN-SUFFIX,hdarea.co,🎯 全球直连
  - DOMAIN-SUFFIX,hdatmos.club,🎯 全球直连
  - DOMAIN-SUFFIX,hdbd.us,🎯 全球直连
  - DOMAIN-SUFFIX,hdbits.org,🎯 全球直连
  - DOMAIN-SUFFIX,hdchina.org,🎯 全球直连
  - DOMAIN-SUFFIX,hdcity.city,🎯 全球直连
  - DOMAIN-SUFFIX,hddolby.com,🎯 全球直连
  - DOMAIN-SUFFIX,hdfans.org,🎯 全球直连
  - DOMAIN-SUFFIX,hdhome.org,🎯 全球直连
  - DOMAIN-SUFFIX,hdpost.top,🎯 全球直连
  - DOMAIN-SUFFIX,hdroute.org,🎯 全球直连
  - DOMAIN-SUFFIX,hdsky.me,🎯 全球直连
  - DOMAIN-SUFFIX,hdstreet.club,🎯 全球直连
  - DOMAIN-SUFFIX,hdtime.org,🎯 全球直连
  - DOMAIN-SUFFIX,hdupt.com,🎯 全球直连
  - DOMAIN-SUFFIX,hdzone.me,🎯 全球直连
  - DOMAIN-SUFFIX,hhanclub.top,🎯 全球直连
  - DOMAIN-SUFFIX,hitpt.com,🎯 全球直连
  - DOMAIN-SUFFIX,hitpt.org,🎯 全球直连
  - DOMAIN-SUFFIX,hudbt.hust.edu.cn,🎯 全球直连
  - DOMAIN-SUFFIX,icetorrent.org,🎯 全球直连
  - DOMAIN-SUFFIX,iptorrents.com,🎯 全球直连
  - DOMAIN-SUFFIX,j99.info,🎯 全球直连
  - DOMAIN-SUFFIX,joyhd.net,🎯 全球直连
  - DOMAIN-SUFFIX,jpopsuki.eu,🎯 全球直连
  - DOMAIN-SUFFIX,karagarga.in,🎯 全球直连
  - DOMAIN-SUFFIX,keepfrds.com,🎯 全球直连
  - DOMAIN-SUFFIX,landof.tv,🎯 全球直连
  - DOMAIN-SUFFIX,leaguehd.com,🎯 全球直连
  - DOMAIN-SUFFIX,lemonhd.org,🎯 全球直连
  - DOMAIN-SUFFIX,lztr.me,🎯 全球直连
  - DOMAIN-SUFFIX,m-team.cc,🎯 全球直连
  - DOMAIN-SUFFIX,madsrevolution.net,🎯 全球直连
  - DOMAIN-SUFFIX,moecat.best,🎯 全球直连
  - DOMAIN-SUFFIX,morethan.tv,🎯 全球直连
  - DOMAIN-SUFFIX,msg.vg,🎯 全球直连
  - DOMAIN-SUFFIX,myanonamouse.net,🎯 全球直连
  - DOMAIN-SUFFIX,nanyangpt.com,🎯 全球直连
  - DOMAIN-SUFFIX,ncore.cc,🎯 全球直连
  - DOMAIN-SUFFIX,nebulance.io,🎯 全球直连
  - DOMAIN-SUFFIX,nicept.net,🎯 全球直连
  - DOMAIN-SUFFIX,npupt.com,🎯 全球直连
  - DOMAIN-SUFFIX,nwsuaf6.edu.cn,🎯 全球直连
  - DOMAIN-SUFFIX,open.cd,🎯 全球直连
  - DOMAIN-SUFFIX,oppaiti.me,🎯 全球直连
  - DOMAIN-SUFFIX,orpheus.network,🎯 全球直连
  - DOMAIN-SUFFIX,ourbits.club,🎯 全球直连
  - DOMAIN-SUFFIX,passthepopcorn.me,🎯 全球直连
  - DOMAIN-SUFFIX,pornbits.net,🎯 全球直连
  - DOMAIN-SUFFIX,privatehd.to,🎯 全球直连
  - DOMAIN-SUFFIX,pterclub.com,🎯 全球直连
  - DOMAIN-SUFFIX,pthome.net,🎯 全球直连
  - DOMAIN-SUFFIX,ptsbao.club,🎯 全球直连
  - DOMAIN-SUFFIX,pttime.org,🎯 全球直连
  - DOMAIN-SUFFIX,pussytorrents.org,🎯 全球直连
  - DOMAIN-SUFFIX,redacted.ch,🎯 全球直连
  - DOMAIN-SUFFIX,sdbits.org,🎯 全球直连
  - DOMAIN-SUFFIX,sharkpt.net,🎯 全球直连
  - DOMAIN-SUFFIX,sjtu.edu.cn,🎯 全球直连
  - DOMAIN-SUFFIX,skyey2.com,🎯 全球直连
  - DOMAIN-SUFFIX,soulvoice.club,🎯 全球直连
  - DOMAIN-SUFFIX,springsunday.net,🎯 全球直连
  - DOMAIN-SUFFIX,tju.pt,🎯 全球直连
  - DOMAIN-SUFFIX,tjupt.org,🎯 全球直连
  - DOMAIN-SUFFIX,torrentday.com,🎯 全球直连
  - DOMAIN-SUFFIX,torrentleech.org,🎯 全球直连
  - DOMAIN-SUFFIX,torrentseeds.org,🎯 全球直连
  - DOMAIN-SUFFIX,totheglory.im,🎯 全球直连
  - DOMAIN-SUFFIX,trontv.com,🎯 全球直连
  - DOMAIN-SUFFIX,u2.dmhy.org,🎯 全球直连
  - DOMAIN-SUFFIX,uhdbits.org,🎯 全球直连
  - DOMAIN-SUFFIX,xauat6.edu.cn,🎯 全球直连
  - DOMAIN-SUFFIX,teamviewer.com,🎯 全球直连
  - IP-CIDR,139.220.243.27/32,🎯 全球直连,no-resolve
  - IP-CIDR,172.16.102.56/32,🎯 全球直连,no-resolve
  - IP-CIDR,185.188.32.1/28,🎯 全球直连,no-resolve
  - IP-CIDR,221.226.128.146/32,🎯 全球直连,no-resolve
  - IP-CIDR6,2a0b:b580::/48,🎯 全球直连,no-resolve
  - IP-CIDR6,2a0b:b581::/48,🎯 全球直连,no-resolve
  - IP-CIDR6,2a0b:b582::/48,🎯 全球直连,no-resolve
  - IP-CIDR6,2a0b:b583::/48,🎯 全球直连,no-resolve
  - DOMAIN-SUFFIX,baomitu.com,🎯 全球直连
  - DOMAIN-SUFFIX,bootcss.com,🎯 全球直连
  - DOMAIN-SUFFIX,jiasule.com,🎯 全球直连
  - DOMAIN-SUFFIX,staticfile.org,🎯 全球直连
  - DOMAIN-SUFFIX,upaiyun.com,🎯 全球直连
  - DOMAIN-SUFFIX,10010.com,🎯 全球直连
  - DOMAIN-SUFFIX,115.com,🎯 全球直连
  - DOMAIN-SUFFIX,12306.com,🎯 全球直连
  - DOMAIN-SUFFIX,17173.com,🎯 全球直连
  - DOMAIN-SUFFIX,178.com,🎯 全球直连
  - DOMAIN-SUFFIX,17k.com,🎯 全球直连
  - DOMAIN-SUFFIX,360doc.com,🎯 全球直连
  - DOMAIN-SUFFIX,36kr.com,🎯 全球直连
  - DOMAIN-SUFFIX,3dmgame.com,🎯 全球直连
  - DOMAIN-SUFFIX,51cto.com,🎯 全球直连
  - DOMAIN-SUFFIX,51job.com,🎯 全球直连
  - DOMAIN-SUFFIX,51jobcdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,56.com,🎯 全球直连
  - DOMAIN-SUFFIX,8686c.com,🎯 全球直连
  - DOMAIN-SUFFIX,abchina.com,🎯 全球直连
  - DOMAIN-SUFFIX,abercrombie.com,🎯 全球直连
  - DOMAIN-SUFFIX,acfun.tv,🎯 全球直连
  - DOMAIN-SUFFIX,air-matters.com,🎯 全球直连
  - DOMAIN-SUFFIX,air-matters.io,🎯 全球直连
  - DOMAIN-SUFFIX,aixifan.com,🎯 全球直连
  - DOMAIN-SUFFIX,algocasts.io,🎯 全球直连
  - DOMAIN-SUFFIX,babytree.com,🎯 全球直连
  - DOMAIN-SUFFIX,babytreeimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,baicizhan.com,🎯 全球直连
  - DOMAIN-SUFFIX,baidupan.com,🎯 全球直连
  - DOMAIN-SUFFIX,baike.com,🎯 全球直连
  - DOMAIN-SUFFIX,biqudu.com,🎯 全球直连
  - DOMAIN-SUFFIX,biquge.com,🎯 全球直连
  - DOMAIN-SUFFIX,bitauto.com,🎯 全球直连
  - DOMAIN-SUFFIX,c-ctrip.com,🎯 全球直连
  - DOMAIN-SUFFIX,camera360.com,🎯 全球直连
  - DOMAIN-SUFFIX,cdnmama.com,🎯 全球直连
  - DOMAIN-SUFFIX,chaoxing.com,🎯 全球直连
  - DOMAIN-SUFFIX,che168.com,🎯 全球直连
  - DOMAIN-SUFFIX,chinacache.net,🎯 全球直连
  - DOMAIN-SUFFIX,chinaso.com,🎯 全球直连
  - DOMAIN-SUFFIX,chinaz.com,🎯 全球直连
  - DOMAIN-SUFFIX,chinaz.net,🎯 全球直连
  - DOMAIN-SUFFIX,chuimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,cibntv.net,🎯 全球直连
  - DOMAIN-SUFFIX,clouddn.com,🎯 全球直连
  - DOMAIN-SUFFIX,cloudxns.net,🎯 全球直连
  - DOMAIN-SUFFIX,cn163.net,🎯 全球直连
  - DOMAIN-SUFFIX,cnblogs.com,🎯 全球直连
  - DOMAIN-SUFFIX,cnki.net,🎯 全球直连
  - DOMAIN-SUFFIX,cnmstl.net,🎯 全球直连
  - DOMAIN-SUFFIX,coolapk.com,🎯 全球直连
  - DOMAIN-SUFFIX,coolapkmarket.com,🎯 全球直连
  - DOMAIN-SUFFIX,csdn.net,🎯 全球直连
  - DOMAIN-SUFFIX,ctrip.com,🎯 全球直连
  - DOMAIN-SUFFIX,dangdang.com,🎯 全球直连
  - DOMAIN-SUFFIX,dfcfw.com,🎯 全球直连
  - DOMAIN-SUFFIX,dianping.com,🎯 全球直连
  - DOMAIN-SUFFIX,dilidili.wang,🎯 全球直连
  - DOMAIN-SUFFIX,douban.com,🎯 全球直连
  - DOMAIN-SUFFIX,doubanio.com,🎯 全球直连
  - DOMAIN-SUFFIX,dpfile.com,🎯 全球直连
  - DOMAIN-SUFFIX,duowan.com,🎯 全球直连
  - DOMAIN-SUFFIX,dxycdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,dytt8.net,🎯 全球直连
  - DOMAIN-SUFFIX,easou.com,🎯 全球直连
  - DOMAIN-SUFFIX,eastday.com,🎯 全球直连
  - DOMAIN-SUFFIX,eastmoney.com,🎯 全球直连
  - DOMAIN-SUFFIX,ecitic.com,🎯 全球直连
  - DOMAIN-SUFFIX,ewqcxz.com,🎯 全球直连
  - DOMAIN-SUFFIX,fang.com,🎯 全球直连
  - DOMAIN-SUFFIX,fantasy.tv,🎯 全球直连
  - DOMAIN-SUFFIX,feng.com,🎯 全球直连
  - DOMAIN-SUFFIX,fengkongcloud.com,🎯 全球直连
  - DOMAIN-SUFFIX,fir.im,🎯 全球直连
  - DOMAIN-SUFFIX,frdic.com,🎯 全球直连
  - DOMAIN-SUFFIX,fresh-ideas.cc,🎯 全球直连
  - DOMAIN-SUFFIX,ganji.com,🎯 全球直连
  - DOMAIN-SUFFIX,ganjistatic1.com,🎯 全球直连
  - DOMAIN-SUFFIX,geetest.com,🎯 全球直连
  - DOMAIN-SUFFIX,geilicdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,ghpym.com,🎯 全球直连
  - DOMAIN-SUFFIX,godic.net,🎯 全球直连
  - DOMAIN-SUFFIX,guazi.com,🎯 全球直连
  - DOMAIN-SUFFIX,gwdang.com,🎯 全球直连
  - DOMAIN-SUFFIX,gzlzfm.com,🎯 全球直连
  - DOMAIN-SUFFIX,haibian.com,🎯 全球直连
  - DOMAIN-SUFFIX,haosou.com,🎯 全球直连
  - DOMAIN-SUFFIX,hollisterco.com,🎯 全球直连
  - DOMAIN-SUFFIX,hongxiu.com,🎯 全球直连
  - DOMAIN-SUFFIX,huajiao.com,🎯 全球直连
  - DOMAIN-SUFFIX,hupu.com,🎯 全球直连
  - DOMAIN-SUFFIX,huxiucdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,huya.com,🎯 全球直连
  - DOMAIN-SUFFIX,ifeng.com,🎯 全球直连
  - DOMAIN-SUFFIX,ifengimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,images-amazon.com,🎯 全球直连
  - DOMAIN-SUFFIX,infzm.com,🎯 全球直连
  - DOMAIN-SUFFIX,ipip.net,🎯 全球直连
  - DOMAIN-SUFFIX,it168.com,🎯 全球直连
  - DOMAIN-SUFFIX,ithome.com,🎯 全球直连
  - DOMAIN-SUFFIX,ixdzs.com,🎯 全球直连
  - DOMAIN-SUFFIX,jianguoyun.com,🎯 全球直连
  - DOMAIN-SUFFIX,jianshu.com,🎯 全球直连
  - DOMAIN-SUFFIX,jianshu.io,🎯 全球直连
  - DOMAIN-SUFFIX,jianshuapi.com,🎯 全球直连
  - DOMAIN-SUFFIX,jiathis.com,🎯 全球直连
  - DOMAIN-SUFFIX,jmstatic.com,🎯 全球直连
  - DOMAIN-SUFFIX,jumei.com,🎯 全球直连
  - DOMAIN-SUFFIX,kaola.com,🎯 全球直连
  - DOMAIN-SUFFIX,knewone.com,🎯 全球直连
  - DOMAIN-SUFFIX,koowo.com,🎯 全球直连
  - DOMAIN-SUFFIX,ksyungslb.com,🎯 全球直连
  - DOMAIN-SUFFIX,kuaidi100.com,🎯 全球直连
  - DOMAIN-SUFFIX,kugou.com,🎯 全球直连
  - DOMAIN-SUFFIX,lancdns.com,🎯 全球直连
  - DOMAIN-SUFFIX,landiannews.com,🎯 全球直连
  - DOMAIN-SUFFIX,lanzou.com,🎯 全球直连
  - DOMAIN-SUFFIX,lanzoui.com,🎯 全球直连
  - DOMAIN-SUFFIX,lanzoux.com,🎯 全球直连
  - DOMAIN-SUFFIX,lemicp.com,🎯 全球直连
  - DOMAIN-SUFFIX,letitfly.me,🎯 全球直连
  - DOMAIN-SUFFIX,lizhi.fm,🎯 全球直连
  - DOMAIN-SUFFIX,lizhi.io,🎯 全球直连
  - DOMAIN-SUFFIX,lizhifm.com,🎯 全球直连
  - DOMAIN-SUFFIX,luoo.net,🎯 全球直连
  - DOMAIN-SUFFIX,lvmama.com,🎯 全球直连
  - DOMAIN-SUFFIX,lxdns.com,🎯 全球直连
  - DOMAIN-SUFFIX,maoyan.com,🎯 全球直连
  - DOMAIN-SUFFIX,meilishuo.com,🎯 全球直连
  - DOMAIN-SUFFIX,meituan.com,🎯 全球直连
  - DOMAIN-SUFFIX,meituan.net,🎯 全球直连
  - DOMAIN-SUFFIX,meizu.com,🎯 全球直连
  - DOMAIN-SUFFIX,migucloud.com,🎯 全球直连
  - DOMAIN-SUFFIX,miguvideo.com,🎯 全球直连
  - DOMAIN-SUFFIX,mobike.com,🎯 全球直连
  - DOMAIN-SUFFIX,mogu.com,🎯 全球直连
  - DOMAIN-SUFFIX,mogucdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,mogujie.com,🎯 全球直连
  - DOMAIN-SUFFIX,moji.com,🎯 全球直连
  - DOMAIN-SUFFIX,moke.com,🎯 全球直连
  - DOMAIN-SUFFIX,msstatic.com,🎯 全球直连
  - DOMAIN-SUFFIX,mubu.com,🎯 全球直连
  - DOMAIN-SUFFIX,myunlu.com,🎯 全球直连
  - DOMAIN-SUFFIX,nruan.com,🎯 全球直连
  - DOMAIN-SUFFIX,nuomi.com,🎯 全球直连
  - DOMAIN-SUFFIX,onedns.net,🎯 全球直连
  - DOMAIN-SUFFIX,oneplus.com,🎯 全球直连
  - DOMAIN-SUFFIX,onlinedown.net,🎯 全球直连
  - DOMAIN-SUFFIX,oppo.com,🎯 全球直连
  - DOMAIN-SUFFIX,oracle.com,🎯 全球直连
  - DOMAIN-SUFFIX,oschina.net,🎯 全球直连
  - DOMAIN-SUFFIX,ourdvs.com,🎯 全球直连
  - DOMAIN-SUFFIX,polyv.net,🎯 全球直连
  - DOMAIN-SUFFIX,qbox.me,🎯 全球直连
  - DOMAIN-SUFFIX,qcloud.com,🎯 全球直连
  - DOMAIN-SUFFIX,qcloudcdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,qdaily.com,🎯 全球直连
  - DOMAIN-SUFFIX,qdmm.com,🎯 全球直连
  - DOMAIN-SUFFIX,qhimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,qianqian.com,🎯 全球直连
  - DOMAIN-SUFFIX,qidian.com,🎯 全球直连
  - DOMAIN-SUFFIX,qihucdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,qin.io,🎯 全球直连
  - DOMAIN-SUFFIX,qiniu.com,🎯 全球直连
  - DOMAIN-SUFFIX,qiniucdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,qiniudn.com,🎯 全球直连
  - DOMAIN-SUFFIX,qiushibaike.com,🎯 全球直连
  - DOMAIN-SUFFIX,quanmin.tv,🎯 全球直连
  - DOMAIN-SUFFIX,qunar.com,🎯 全球直连
  - DOMAIN-SUFFIX,qunarzz.com,🎯 全球直连
  - DOMAIN-SUFFIX,realme.com,🎯 全球直连
  - DOMAIN-SUFFIX,repaik.com,🎯 全球直连
  - DOMAIN-SUFFIX,ruguoapp.com,🎯 全球直连
  - DOMAIN-SUFFIX,runoob.com,🎯 全球直连
  - DOMAIN-SUFFIX,sankuai.com,🎯 全球直连
  - DOMAIN-SUFFIX,segmentfault.com,🎯 全球直连
  - DOMAIN-SUFFIX,sf-express.com,🎯 全球直连
  - DOMAIN-SUFFIX,shumilou.net,🎯 全球直连
  - DOMAIN-SUFFIX,simplecd.me,🎯 全球直连
  - DOMAIN-SUFFIX,smzdm.com,🎯 全球直连
  - DOMAIN-SUFFIX,snwx.com,🎯 全球直连
  - DOMAIN-SUFFIX,soufunimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,sspai.com,🎯 全球直连
  - DOMAIN-SUFFIX,startssl.com,🎯 全球直连
  - DOMAIN-SUFFIX,suning.com,🎯 全球直连
  - DOMAIN-SUFFIX,synology.com,🎯 全球直连
  - DOMAIN-SUFFIX,taihe.com,🎯 全球直连
  - DOMAIN-SUFFIX,th-sjy.com,🎯 全球直连
  - DOMAIN-SUFFIX,tianqi.com,🎯 全球直连
  - DOMAIN-SUFFIX,tianqistatic.com,🎯 全球直连
  - DOMAIN-SUFFIX,tianyancha.com,🎯 全球直连
  - DOMAIN-SUFFIX,tianyaui.com,🎯 全球直连
  - DOMAIN-SUFFIX,tietuku.com,🎯 全球直连
  - DOMAIN-SUFFIX,tiexue.net,🎯 全球直连
  - DOMAIN-SUFFIX,tmiaoo.com,🎯 全球直连
  - DOMAIN-SUFFIX,trip.com,🎯 全球直连
  - DOMAIN-SUFFIX,ttmeiju.com,🎯 全球直连
  - DOMAIN-SUFFIX,tudou.com,🎯 全球直连
  - DOMAIN-SUFFIX,tuniu.com,🎯 全球直连
  - DOMAIN-SUFFIX,tuniucdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,umengcloud.com,🎯 全球直连
  - DOMAIN-SUFFIX,upyun.com,🎯 全球直连
  - DOMAIN-SUFFIX,uxengine.net,🎯 全球直连
  - DOMAIN-SUFFIX,videocc.net,🎯 全球直连
  - DOMAIN-SUFFIX,vivo.com,🎯 全球直连
  - DOMAIN-SUFFIX,wandoujia.com,🎯 全球直连
  - DOMAIN-SUFFIX,weather.com,🎯 全球直连
  - DOMAIN-SUFFIX,weico.cc,🎯 全球直连
  - DOMAIN-SUFFIX,weidian.com,🎯 全球直连
  - DOMAIN-SUFFIX,weiphone.com,🎯 全球直连
  - DOMAIN-SUFFIX,weiphone.net,🎯 全球直连
  - DOMAIN-SUFFIX,womai.com,🎯 全球直连
  - DOMAIN-SUFFIX,wscdns.com,🎯 全球直连
  - DOMAIN-SUFFIX,xdrig.com,🎯 全球直连
  - DOMAIN-SUFFIX,xhscdn.com,🎯 全球直连
  - DOMAIN-SUFFIX,xiachufang.com,🎯 全球直连
  - DOMAIN-SUFFIX,xiaohongshu.com,🎯 全球直连
  - DOMAIN-SUFFIX,xiaojukeji.com,🎯 全球直连
  - DOMAIN-SUFFIX,xinhuanet.com,🎯 全球直连
  - DOMAIN-SUFFIX,xip.io,🎯 全球直连
  - DOMAIN-SUFFIX,xitek.com,🎯 全球直连
  - DOMAIN-SUFFIX,xiumi.us,🎯 全球直连
  - DOMAIN-SUFFIX,xslb.net,🎯 全球直连
  - DOMAIN-SUFFIX,xueqiu.com,🎯 全球直连
  - DOMAIN-SUFFIX,yach.me,🎯 全球直连
  - DOMAIN-SUFFIX,yeepay.com,🎯 全球直连
  - DOMAIN-SUFFIX,yhd.com,🎯 全球直连
  - DOMAIN-SUFFIX,yihaodianimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,yinxiang.com,🎯 全球直连
  - DOMAIN-SUFFIX,yinyuetai.com,🎯 全球直连
  - DOMAIN-SUFFIX,yixia.com,🎯 全球直连
  - DOMAIN-SUFFIX,ys168.com,🎯 全球直连
  - DOMAIN-SUFFIX,yuewen.com,🎯 全球直连
  - DOMAIN-SUFFIX,yy.com,🎯 全球直连
  - DOMAIN-SUFFIX,yystatic.com,🎯 全球直连
  - DOMAIN-SUFFIX,zealer.com,🎯 全球直连
  - DOMAIN-SUFFIX,zhangzishi.cc,🎯 全球直连
  - DOMAIN-SUFFIX,zhanqi.tv,🎯 全球直连
  - DOMAIN-SUFFIX,zhaopin.com,🎯 全球直连
  - DOMAIN-SUFFIX,zhihu.com,🎯 全球直连
  - DOMAIN-SUFFIX,zhimg.com,🎯 全球直连
  - DOMAIN-SUFFIX,zhongsou.com,🎯 全球直连
  - DOMAIN-SUFFIX,zhuihd.com,🎯 全球直连
  - IP-CIDR,8.128.0.0/10,🎯 全球直连,no-resolve
  - IP-CIDR,8.208.0.0/12,🎯 全球直连,no-resolve
  - IP-CIDR,14.1.112.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,41.222.240.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,41.223.119.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,43.242.168.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,45.112.212.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,47.52.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,47.56.0.0/15,🎯 全球直连,no-resolve
  - IP-CIDR,47.74.0.0/15,🎯 全球直连,no-resolve
  - IP-CIDR,47.76.0.0/14,🎯 全球直连,no-resolve
  - IP-CIDR,47.80.0.0/12,🎯 全球直连,no-resolve
  - IP-CIDR,47.235.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,47.236.0.0/14,🎯 全球直连,no-resolve
  - IP-CIDR,47.240.0.0/14,🎯 全球直连,no-resolve
  - IP-CIDR,47.244.0.0/15,🎯 全球直连,no-resolve
  - IP-CIDR,47.246.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,47.250.0.0/15,🎯 全球直连,no-resolve
  - IP-CIDR,47.252.0.0/15,🎯 全球直连,no-resolve
  - IP-CIDR,47.254.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,59.82.0.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,59.82.240.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,59.82.248.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,72.254.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,103.38.56.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.52.76.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.206.40.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,110.76.21.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,110.76.23.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,112.125.0.0/17,🎯 全球直连,no-resolve
  - IP-CIDR,116.251.64.0/18,🎯 全球直连,no-resolve
  - IP-CIDR,119.38.208.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,119.38.224.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,119.42.224.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,139.95.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,140.205.1.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,140.205.122.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,147.139.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,149.129.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,155.102.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,161.117.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,163.181.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,170.33.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,198.11.128.0/18,🎯 全球直连,no-resolve
  - IP-CIDR,205.204.96.0/19,🎯 全球直连,no-resolve
  - IP-CIDR,19.28.0.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,45.40.192.0/19,🎯 全球直连,no-resolve
  - IP-CIDR,49.51.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,62.234.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,94.191.0.0/17,🎯 全球直连,no-resolve
  - IP-CIDR,103.7.28.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.116.50.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,103.231.60.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,109.244.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,111.30.128.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,111.30.136.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,111.30.139.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,111.30.140.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,115.159.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,119.28.0.0/15,🎯 全球直连,no-resolve
  - IP-CIDR,120.88.56.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,121.51.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,129.28.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,129.204.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,129.211.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,132.232.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,134.175.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,146.56.192.0/18,🎯 全球直连,no-resolve
  - IP-CIDR,148.70.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,150.109.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,152.136.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,162.14.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,162.62.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,170.106.130.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,182.254.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,188.131.128.0/17,🎯 全球直连,no-resolve
  - IP-CIDR,203.195.128.0/17,🎯 全球直连,no-resolve
  - IP-CIDR,203.205.128.0/17,🎯 全球直连,no-resolve
  - IP-CIDR,210.4.138.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,211.152.128.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,211.152.132.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,211.152.148.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,212.64.0.0/17,🎯 全球直连,no-resolve
  - IP-CIDR,212.129.128.0/17,🎯 全球直连,no-resolve
  - IP-CIDR,45.113.192.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,63.217.23.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,63.243.252.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,103.235.44.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,104.193.88.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,106.12.0.0/15,🎯 全球直连,no-resolve
  - IP-CIDR,114.28.224.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,119.63.192.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,180.76.0.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,180.76.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,182.61.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,185.10.104.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,202.46.48.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,203.90.238.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,43.254.0.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,45.249.212.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,49.4.0.0/17,🎯 全球直连,no-resolve
  - IP-CIDR,78.101.192.0/19,🎯 全球直连,no-resolve
  - IP-CIDR,78.101.224.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,81.52.161.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,85.97.220.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.31.200.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.69.140.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,103.218.216.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,114.115.128.0/17,🎯 全球直连,no-resolve
  - IP-CIDR,114.116.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,116.63.128.0/18,🎯 全球直连,no-resolve
  - IP-CIDR,116.66.184.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,116.71.96.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,116.71.128.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,116.71.136.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,116.71.141.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,116.71.142.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,116.71.243.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,116.71.244.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,116.71.251.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,117.78.0.0/18,🎯 全球直连,no-resolve
  - IP-CIDR,119.3.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,119.8.0.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,119.8.32.0/19,🎯 全球直连,no-resolve
  - IP-CIDR,121.36.0.0/17,🎯 全球直连,no-resolve
  - IP-CIDR,121.36.128.0/18,🎯 全球直连,no-resolve
  - IP-CIDR,121.37.0.0/17,🎯 全球直连,no-resolve
  - IP-CIDR,122.112.128.0/17,🎯 全球直连,no-resolve
  - IP-CIDR,139.9.0.0/18,🎯 全球直连,no-resolve
  - IP-CIDR,139.9.64.0/19,🎯 全球直连,no-resolve
  - IP-CIDR,139.9.100.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,139.9.104.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,139.9.112.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,139.9.128.0/18,🎯 全球直连,no-resolve
  - IP-CIDR,139.9.192.0/19,🎯 全球直连,no-resolve
  - IP-CIDR,139.9.224.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,139.9.240.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,139.9.248.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,139.159.128.0/19,🎯 全球直连,no-resolve
  - IP-CIDR,139.159.160.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,139.159.164.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,139.159.168.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,139.159.176.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,139.159.192.0/18,🎯 全球直连,no-resolve
  - IP-CIDR,159.138.0.0/18,🎯 全球直连,no-resolve
  - IP-CIDR,159.138.64.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,159.138.79.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,159.138.80.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,159.138.96.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,159.138.112.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,159.138.125.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,159.138.128.0/18,🎯 全球直连,no-resolve
  - IP-CIDR,159.138.192.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,159.138.223.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,159.138.224.0/19,🎯 全球直连,no-resolve
  - IP-CIDR,168.195.92.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,185.176.76.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,197.199.0.0/18,🎯 全球直连,no-resolve
  - IP-CIDR,197.210.163.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,197.252.1.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,197.252.2.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,197.252.4.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,197.252.8.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,200.32.52.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,200.32.54.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,200.32.57.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.0.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.4.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.8.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.11.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.13.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.20.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.22.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.24.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.26.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.29.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.33.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.38.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.40.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.43.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.48.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,203.135.50.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,42.186.0.0/16,🎯 全球直连,no-resolve
  - IP-CIDR,45.127.128.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,45.195.24.0/24,🎯 全球直连,no-resolve
  - IP-CIDR,45.253.132.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,45.253.240.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,45.254.48.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,59.111.0.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,59.111.128.0/17,🎯 全球直连,no-resolve
  - IP-CIDR,103.71.120.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,103.71.128.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.71.196.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.71.200.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.72.12.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.72.18.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,103.72.24.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.72.28.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,103.72.38.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,103.72.40.0/23,🎯 全球直连,no-resolve
  - IP-CIDR,103.72.44.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.72.48.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,103.72.128.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,103.74.24.0/21,🎯 全球直连,no-resolve
  - IP-CIDR,103.74.48.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.126.92.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.129.252.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.131.252.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.135.240.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,103.196.64.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,106.2.32.0/19,🎯 全球直连,no-resolve
  - IP-CIDR,106.2.64.0/18,🎯 全球直连,no-resolve
  - IP-CIDR,114.113.196.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,114.113.200.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,115.236.112.0/20,🎯 全球直连,no-resolve
  - IP-CIDR,115.238.76.0/22,🎯 全球直连,no-resolve
  - IP-CIDR,123.58.160.0/19,🎯 全球直连,no-resolve
  - IP-CIDR,223.252.192.0/19,🎯 全球直连,no-resolve
  - IP-CIDR,101.198.128.0/18,🎯 全球直连,no-resolve
  - IP-CIDR,101.198.192.0/19,🎯 全球直连,no-resolve
  - IP-CIDR,101.199.196.0/22,🎯 全球直连,no-resolve
  - GEOIP,CN,🎯 全球直连
  - MATCH,🐟 漏网之鱼
 SMALLFLOWERCAT1995

    # 写入 sing-box 客户端配置到 client-sing-box-config.json 文件
    cat <<SMALLFLOWERCAT1995 | sudo tee client-sing-box-config.json >/dev/null
{
	"log": {
		"level": "debug",
		"timestamp": true
	},
	"experimental": {
		"clash_api": {
			"external_controller": "127.0.0.1:9090",
			"external_ui": "ui",
			"secret": "",
			"external_ui_download_url": "https://mirror.ghproxy.com/https://github.com/MetaCubeX/Yacd-meta/archive/gh-pages.zip",
			"external_ui_download_detour": "direct",
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
				"address": "tls://8.8.8.8",
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
			}
		],
		"strategy": "ipv4_only"
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
				"$SB_VM_PROTOCOL_OUT_TAG",
				"$SB_H2_PROTOCOL_OUT_TAG"
			]
		},
		{
			"tag": "OpenAI",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"TaiWan",
				"Singapore",
				"Japan",
				"America",
				"Others"
			],
			"default": "America"
		},
		{
			"tag": "Google",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"HongKong",
				"TaiWan",
				"Singapore",
				"Japan",
				"America",
				"Others"
			]
		},
		{
			"tag": "Telegram",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"HongKong",
				"TaiWan",
				"Singapore",
				"Japan",
				"America",
				"Others"
			]
		},
		{
			"tag": "Twitter",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"HongKong",
				"TaiWan",
				"Singapore",
				"Japan",
				"America",
				"Others"
			]
		},
		{
			"tag": "Facebook",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"HongKong",
				"TaiWan",
				"Singapore",
				"Japan",
				"America",
				"Others"
			]
		},
		{
			"tag": "BiliBili",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"direct",
				"HongKong",
				"TaiWan"
			]
		},
		{
			"tag": "Bahamut",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"HongKong",
				"TaiWan",
				"Singapore",
				"Japan",
				"America",
				"Others"
			],
			"default": "TaiWan"
		},
		{
			"tag": "Spotify",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"HongKong",
				"TaiWan",
				"Singapore",
				"Japan",
				"America",
				"Others"
			]
		},
		{
			"tag": "TikTok",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"HongKong",
				"TaiWan",
				"Singapore",
				"Japan",
				"America"
			],
			"default": "Singapore"
		},
		{
			"tag": "NETFLIX",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"HongKong",
				"TaiWan",
				"Singapore",
				"Japan",
				"America",
				"Others"
			]
		},
		{
			"tag": "Disney+",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"HongKong",
				"TaiWan",
				"Singapore",
				"Japan",
				"America",
				"Others"
			]
		},
		{
			"tag": "Apple",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"direct",
				"HongKong",
				"TaiWan",
				"Singapore",
				"Japan",
				"America",
				"Others"
			]
		},
		{
			"tag": "Microsoft",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"direct",
				"HongKong",
				"TaiWan",
				"Singapore",
				"Japan",
				"America",
				"Others"
			]
		},
		{
			"tag": "Games",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"direct",
				"HongKong",
				"TaiWan",
				"Singapore",
				"Japan",
				"America",
				"Others"
			]
		},
		{
			"tag": "Streaming",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"HongKong",
				"TaiWan",
				"Singapore",
				"Japan",
				"America",
				"Others"
			]
		},
		{
			"tag": "Global",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"direct",
				"HongKong",
				"TaiWan",
				"Singapore",
				"Japan",
				"America",
				"Others"
			],
			"default": "HongKong"
		},
		{
			"tag": "China",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"direct",
				"$SB_ALL_PROTOCOL_OUT_TAG"
			]
		},
		{
			"tag": "AdBlock",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"block",
				"direct"
			]
		},
		{
			"tag": "HongKong",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"$SB_V_PROTOCOL_OUT_TAG_A",
				"$SB_VM_PROTOCOL_OUT_TAG_A",
				"$SB_H2_PROTOCOL_OUT_TAG_A",
				"$SB_ALL_PROTOCOL_OUT_TAG"
			]
		},
		{
			"tag": "TaiWan",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"$SB_V_PROTOCOL_OUT_TAG_A",
				"$SB_VM_PROTOCOL_OUT_TAG_A",
				"$SB_H2_PROTOCOL_OUT_TAG_A",
				"$SB_ALL_PROTOCOL_OUT_TAG"
			]
		},
		{
			"tag": "Singapore",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"$SB_V_PROTOCOL_OUT_TAG_A",
				"$SB_VM_PROTOCOL_OUT_TAG_A",
				"$SB_H2_PROTOCOL_OUT_TAG_A",
				"$SB_ALL_PROTOCOL_OUT_TAG"
			]
		},
		{
			"tag": "Japan",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"$SB_V_PROTOCOL_OUT_TAG_A",
				"$SB_VM_PROTOCOL_OUT_TAG_A",
				"$SB_H2_PROTOCOL_OUT_TAG_A",
				"$SB_ALL_PROTOCOL_OUT_TAG"
			]
		},
		{
			"tag": "America",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"$SB_V_PROTOCOL_OUT_TAG_A",
				"$SB_VM_PROTOCOL_OUT_TAG_A",
				"$SB_H2_PROTOCOL_OUT_TAG_A",
				"$SB_ALL_PROTOCOL_OUT_TAG"
			]
		},
		{
			"tag": "Others",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"$SB_V_PROTOCOL_OUT_TAG_A",
				"$SB_VM_PROTOCOL_OUT_TAG_A",
				"$SB_H2_PROTOCOL_OUT_TAG_A",
				"$SB_ALL_PROTOCOL_OUT_TAG"
			]
		},
		{
			"tag": "$SB_V_PROTOCOL_OUT_TAG",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"$SB_V_PROTOCOL_OUT_TAG_A"
			]
		},
		{
			"tag": "$SB_VM_PROTOCOL_OUT_TAG",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"$SB_VM_PROTOCOL_OUT_TAG_A"
			]
		},
		{
			"tag": "$SB_H2_PROTOCOL_OUT_TAG",
			"type": "$SB_ALL_PROTOCOL_OUT_TYPE",
			"outbounds": [
				"$SB_H2_PROTOCOL_OUT_TAG_A"
			]
		},
		{
			"tag": "auto",
			"type": "urltest",
			"outbounds": [
				"$SB_V_PROTOCOL_OUT_TAG_A",
				"$SB_VM_PROTOCOL_OUT_TAG_A",
				"$SB_H2_PROTOCOL_OUT_TAG_A"
			],
			"url": "http://www.gstatic.com/generate_204",
			"interval": "5m",
			"tolerance": 50
		},
		{
			"type": "direct",
			"tag": "direct"
		},
		{
			"type": "dns",
			"tag": "dns-out"
		},
		{
			"type": "block",
			"tag": "block"
		},
		{
			"type": "$V_PROTOCOL",
			"tag": "$SB_V_PROTOCOL_OUT_TAG_A",
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
			"server": "$VM_WEBSITE",
			"server_port": $CLOUDFLARED_PORT,
			"tag": "$SB_VM_PROTOCOL_OUT_TAG_A",
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
				"path": "$VM_PATH",
				"type": "$VM_TYPE",
				"max_early_data": 2048,
				"early_data_header_name": "Sec-WebSocket-Protocol"
			},
			"type": "$VM_PROTOCOL",
			"security": "auto",
			"uuid": "$VM_UUID"
		},
		{
			"type": "$H2_PROTOCOL",
			"server": "$H2_N_DOMAIN",
			"server_port": $H2_N_PORT,
			"tag": "$SB_H2_PROTOCOL_OUT_TAG_A",
			"up_mbps": 100,
			"down_mbps": 100,
			"password": "$H2_HEX",
			"network": "tcp",
			"tls": {
				"enabled": true,
				"server_name": "$H2_WEBSITE_CERTIFICATES",
				"insecure": true,
				"alpn": [
					"$H2_TYPE"
				]
			}
		}
	],
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
				"outbound": "AdBlock"
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
				"rule_set": "geosite-openai",
				"outbound": "OpenAI"
			},
			{
				"rule_set": "geosite-youtube",
				"outbound": "Google"
			},
			{
				"rule_set": "geoip-google",
				"outbound": "Google"
			},
			{
				"rule_set": "geosite-google",
				"outbound": "Google"
			},
			{
				"rule_set": "geosite-github",
				"outbound": "Google"
			},
			{
				"rule_set": "geoip-telegram",
				"outbound": "Telegram"
			},
			{
				"rule_set": "geosite-telegram",
				"outbound": "Telegram"
			},
			{
				"rule_set": "geoip-twitter",
				"outbound": "Twitter"
			},
			{
				"rule_set": "geosite-twitter",
				"outbound": "Twitter"
			},
			{
				"rule_set": "geoip-facebook",
				"outbound": "Facebook"
			},
			{
				"rule_set": [
					"geosite-facebook",
					"geosite-instagram"
				],
				"outbound": "Facebook"
			},
			{
				"rule_set": "geoip-bilibili",
				"outbound": "BiliBili"
			},
			{
				"rule_set": "geosite-bilibili",
				"outbound": "BiliBili"
			},
			{
				"rule_set": "geosite-bahamut",
				"outbound": "Bahamut"
			},
			{
				"rule_set": "geosite-spotify",
				"outbound": "Spotify"
			},
			{
				"rule_set": "geosite-tiktok",
				"outbound": "TikTok"
			},
			{
				"rule_set": "geoip-netflix",
				"outbound": "NETFLIX"
			},
			{
				"rule_set": "geosite-netflix",
				"outbound": "NETFLIX"
			},
			{
				"rule_set": "geosite-disney",
				"outbound": "Disney+"
			},
			{
				"rule_set": "geosite-apple",
				"outbound": "Apple"
			},
			{
				"rule_set": "geosite-amazon",
				"outbound": "Apple"
			},
			{
				"rule_set": "geosite-microsoft",
				"outbound": "Microsoft"
			},
			{
				"rule_set": "geosite-category-games",
				"outbound": "Games"
			},
			{
				"rule_set": "geosite-hbo",
				"outbound": "Streaming"
			},
			{
				"rule_set": "geosite-primevideo",
				"outbound": "Streaming"
			},
			{
				"rule_set": "geosite-geolocation-!cn",
				"outbound": "Global"
			},
			{
				"rule_set": "geosite-private",
				"outbound": "direct"
			},
			{
				"ip_is_private": true,
				"outbound": "direct"
			},
			{
				"rule_set": "geoip-cn",
				"outbound": "China"
			},
			{
				"rule_set": "geosite-cn",
				"outbound": "China"
			}
		],
		"rule_set": [
			{
				"tag": "geoip-google",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/google.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geoip-telegram",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/telegram.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geoip-twitter",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/twitter.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geoip-facebook",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/facebook.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geoip-netflix",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/netflix.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geoip-apple",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo-lite/geoip/apple.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geoip-bilibili",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo-lite/geoip/bilibili.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geoip-cn",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/cn.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-private",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/private.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-openai",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/openai.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-youtube",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/youtube.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-google",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/google.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-github",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/github.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-telegram",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/telegram.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-twitter",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/twitter.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-facebook",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/facebook.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-instagram",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/instagram.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-bilibili",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/bilibili.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-bahamut",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/bahamut.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-spotify",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/spotify.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-tiktok",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/tiktok.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-netflix",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/netflix.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-disney",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/disney.srs",
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
				"tag": "geosite-amazon",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/amazon.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-microsoft",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/microsoft.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-category-games",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/category-games.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-hbo",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/hbo.srs",
				"download_detour": "direct"
			},
			{
				"tag": "geosite-primevideo",
				"type": "remote",
				"format": "binary",
				"url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/primevideo.srs",
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
			}
		]
	}
}
SMALLFLOWERCAT1995
    # 发送到邮件所需变量
    # 本机 ip
    HOSTNAME_IP="$(hostname -I)"
    # 终末时间=起始时间+6h
    #F_DATE="$(date -d '${REPORT_DATE}' --date='6 hour' +'%Y-%m-%d %T')"
    F_DATE="$(TZ=':Asia/Shanghai' date +'%Y-%m-%d %T')"
    # 写入 result.txt
    cat <<SMALLFLOWERCAT1995 | sudo tee result.txt >/dev/null
SSH is accessible at: 
$HOSTNAME_IP:22 -> $SSH_N_DOMAIN:$SSH_N_PORT
ssh $USER_NAME@$SSH_N_DOMAIN -o ServerAliveInterval=60 -p $SSH_N_PORT

VLESS is accessible at: 
$HOSTNAME_IP:$V_PORT -> $VLESS_N_DOMAIN:$VLESS_N_PORT
$VLESS_LINK

# VMESS is accessible at: 
# $HOSTNAME_IP:$VM_PORT -> $CLOUDFLARED_DOMAIN:$CLOUDFLARED_PORT
$VMESS_LINK

# HYSTERIA2 is accessible at: 
# $HOSTNAME_IP:$H2_PORT -> $H2_N_DOMAIN:$H2_N_PORT
$HYSTERIA2_LINK

Time Frame is accessible at: 
$REPORT_DATE~$F_DATE
SMALLFLOWERCAT1995
}
# 前戏初始化函数 initall
initall
# 初始化用户密码
createUserNamePassword
# 神秘的分割线
echo "=========================================="
# 下载 CloudflareSpeedTest sing-box cloudflared ngrok 配置并启用
getAndStart
# 神秘的分隔符
echo "=========================================="
# 删除脚本自身
rm -fv set-sing-box.sh
# 清理 bash 记录
echo '' >$HOME/.bash_history
echo '' >$HOME/.bash_logout
history -c
