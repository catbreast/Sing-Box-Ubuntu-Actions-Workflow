#!/usr/bin/env bash
# 前戏初始化函数 initall
initall() {
    # 获取当前日期
    date '+%Y-%m-%d %H:%M:%S'
    # 修改地点时区软连接
    sudo ln -sfv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    # 写入地点时区配置文件
    sudo cat <<SMALLFLOWERCAT1995 | sudo tee /etc/timezone
Asia/Shanghai
SMALLFLOWERCAT1995
    # 重新获取修改地点时区后的时间
    date '+%Y-%m-%d %H:%M:%S'
    # 更新源
    sudo apt update
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
    
    # 写入 sing-box 客户端配置到 client-config.json 文件
    cat <<SMALLFLOWERCAT1995 | sudo tee client-config.json >/dev/null
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
    # 起始时间
    REPORT_DATE="$(TZ=':Asia/Shanghai' date +'%Y-%m-%d %T')"
    # 终末时间=起始时间+6h
    F_DATE="$(date -d '${REPORT_DATE}' --date='6 hour' +'%Y-%m-%d %T')"
    # 写入 result.txt
    cat <<SMALLFLOWERCAT1995 | sudo tee result.txt >/dev/null
SSH is accessible at: 
$HOSTNAME_IP:22 -> $SSH_N_DOMAIN:$SSH_N_PORT
ssh $USER_NAME@$SSH_N_DOMAIN -o ServerAliveInterval=60 -p $SSH_N_PORT

VLESS is accessible at: 
$HOSTNAME_IP:$V_PORT -> $VLESS_N_DOMAIN:$VLESS_N_PORT

# VMESS is accessible at: 
# $HOSTNAME_IP:$VM_PORT -> $CLOUDFLARED_DOMAIN:$CLOUDFLARED_PORT

# HYSTERIA2 is accessible at: 
# $HOSTNAME_IP:$H2_PORT -> $H2_N_DOMAIN:$H2_N_PORT

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
