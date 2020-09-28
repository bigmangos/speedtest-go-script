#!/bin/bash
### 一键安装 speedtest go 版本  #
###    作者：fenghuang          #
###   更新时间：2020-04-19      #

#导入环境变量
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/sbin
export PATH
dir="/usr/speedtest/"

function setout(){
    if [ -e "/usr/bin/yum" ]; then
        yum -y install git wget
    else
        sudo apt-get update
        sudo apt-get install -y wget git
    fi
}

function chk_firewall(){
    if [ -e "/etc/sysconfig/iptables" ]; then
        iptables -I INPUT -p tcp --dport $port -j ACCEPT
        service iptables save
        service iptables restart
    elif [ -e "/etc/firewalld/zones/public.xml" ]; then
        firewall-cmd --zone=public --add-port=$port/tcp --permanent
        firewall-cmd --reload
    elif [ -e "/etc/ufw/before.rules" ]; then
        sudo ufw allow $port/tcp
    fi
}

function del_post() {
    if [ -e "/etc/sysconfig/iptables" ]; then
        sed -i "/^.*$port.*/"d /etc/sysconfig/iptables
        service iptables save
        service iptables restart
    elif [ -e "/etc/firewalld/zones/public.xml" ]; then
        firewall-cmd --zone=public --remove-port=$port/tcp --permanent
        firewall-cmd --reload
    elif [ -e "/etc/ufw/before.rules" ]; then
        sudo ufw delete $port/tcp
    fi
}

function install_go(){
    gov=$(curl -s https://github.com/golang/go/releases|awk '/release-branch/{print $NF;exit;}')
    wget https://golang.org/dl/${gov}.linux-amd64.tar.gz -P /tmp
    tar -C /usr/local -zxf /tmp/${gov}.linux-amd64.tar.gz
    export GOPATH="/usr/go"
}

function input_port(){
    while true
        do
        read -p "请输入监听端口[1-65535]（默认8989）:" port
        [[ -z "${port}" ]] && port="8989"
        echo $((${port}+0)) &>/dev/null
        if [[ $? -eq 0 ]]; then
            if [[ ${port} -ge 1 ]] && [[ ${port} -le 65535 ]]; then
                echo "设置端口:${port}"
                break
            else
                echo "输入错误, 请输入正确的端口."
            fi
        else
            echo "输入错误, 请输入正确的端口."
        fi
        done
}

function change_port(){
    stop
    sleep 2
    input_port
    del_post
    chk_firewall
    cd $dir && sed -i "4s/[0-9]\{1,5\}/$port/g" settings.toml
    start
}

function get_speedtest(){
    if [ -e $dir"speedtest" ]; then
        echo "已经安装，将更新到最新版."
        rm -rf $dir
    fi
    install_go
    cd && git clone https://github.com/librespeed/speedtest-go.git
    cd speedtest
    mkdir $dir && cp -r settings.toml assets $dir
    /usr/local/go/bin/go build -o speedtest main.go
    cp ./speedtest $dir
    cd && rm -rf speedtest go
    cd $dir && sed -i "4s/[0-9]\{1,5\}/$port/g" settings.toml
    cd $dir"assets" && mv example-singleServer-full.html index.html
    rm -rf /usr/local/go /usr/go
}

function start(){
    PID=`pgrep speedtest`
    if [ ! -z $PID ]; then
        echo "已经启动."
        return
    else
        cd $dir && nohup ./speedtest > /var/log/speedtest.log 2>&1 &
        echo "------------------------------------------------"
        echo "启动成功."
        echo "访问IP:$port测速."
    fi
    
}

function stop(){
    PID=`pgrep speedtest`
    if [ ! -z ${PID} ]; then
        kill -9 ${PID}
        echo "停止成功."
    else
        echo "没有启动."
    fi
}


function del(){
    stop
    del_post
    rm -rf $dir
    rm -f /var/log/speedtest.log
    echo "卸载成功."
}

echo "------------------------------------------------"
echo "Speedtest go版本一键安装管理脚本"
echo "1、安装 Speedtest"
echo "2、卸载 Speedtest"
echo "3、修改监听端口"
echo "4、启动 Speedtest"
echo "5、停止 Speedtest"
echo "其它键退出！"
read -p ":" istype
case $istype in
    1)
    input_port
    setout
    get_speedtest
    chk_firewall
    start;;
    2)
    del;;
    3)
    change_port;;
    4)
    start;;
    5)
    stop;;
    *) break
esac
