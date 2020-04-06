#!/bin/bash
### 一键安装 speedtest go 版本  #
###    作者：fenghuang          #
###   更新时间：2020-04-05      #

#导入环境变量
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/sbin
export PATH && source ~/.profile && source /etc/profile
dir=/usr/speedtest/

function setout(){
	if [ -e "/usr/bin/yum" ]
	then
		yum -y install git wget
	else
		sudo apt-get update
		sudo apt-get install -y wget git
	fi
}

function chk_firewall(){
	if [ -e "/etc/sysconfig/iptables" ]
	then
		iptables -I INPUT -p tcp --dport 8989 -j ACCEPT
		service iptables save
		service iptables restart
	elif [ -e "/etc/firewalld/zones/public.xml" ]
	then
		firewall-cmd --zone=public --add-port=8989/tcp --permanent
		firewall-cmd --reload
	elif [ -e "/etc/ufw/before.rules" ]
	then
		sudo ufw allow 8989/tcp
	fi
}

function del_post() {
	if [ -e "/etc/sysconfig/iptables" ]
	then
		sed -i '/^.*8989.*/'d /etc/sysconfig/iptables
		service iptables save
		service iptables restart
	elif [ -e "/etc/firewalld/zones/public.xml" ]
	then
		firewall-cmd --zone=public --remove-port=8989/tcp --permanent
		firewall-cmd --reload
	elif [ -e "/etc/ufw/before.rules" ]
	then
		sudo ufw delete 8989/tcp
	fi
}

function install_go(){
	is_install_go=$(which go)
	if [ -z $is_install_go ]; # 空是真
	then
		wget https://dl.google.com/go/go1.14.1.linux-amd64.tar.gz -P /tmp
		tar -C /usr/local -zxf /tmp/go1.14.1.linux-amd64.tar.gz
		echo -e '\nexport GOROOT=/usr/local/go\nexport PATH=$PATH:$GOROOT/bin\nexport GOPATH=$HOME/go' >> ~/.profile
		source ~/.profile
	fi
}

function get_speedtest(){
	cd && git clone https://github.com/librespeed/speedtest
	cd speedtest
	git checkout remotes/origin/go
    mkdir $dir && cp -r settings.toml assets $dir
	go build -o speedtest main.go
	cp ./speedtest $dir
	cd && rm -rf speedtest go
}

function start(){
	cd $dir"assets"
	mv example-singleServer-full.html index.html
	cd .. && nohup ./speedtest > /var/log/speedtest.log 2>&1 &
	echo "------------------------------------------------"
}

function del(){
	kill -9 $(pgrep 'speedtest')
	del_post
	rm -rf /usr/speedtest/
	rm -f /var/log/speedtest.log
}

echo "------------------------------------------------"
echo "Speedtest go版本一键安装脚本"
echo "1) 安装 Speedtest"
echo "2) 卸载 Speedtest"
echo "其它键退出！"
read -p ":" istype
case $istype in
    1) 
    setout
    install_go
    get_speedtest
    chk_firewall
    start
    echo "安装成功."
    echo "访问IP:8989测速.";;
    2) 
    del
    echo "卸载成功.";;
    *) break
esac
