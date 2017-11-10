#!/bin/bash
# -*- coding: UTF-8 -*-
SELFPATH=$(cd "$(dirname "$0")"; pwd)
echo '请输入一个域名'
read DOMAIN
install_yilai(){
	yum -y install zlib-devel openssl-devel perl hg cpio expat-devel gettext-devel curl curl-devel perl-ExtUtils-MakeMaker hg wget gcc gcc-c++  build-essential mercurial zip
}

# 安装git
install_git(){
	unstall_git
	if [ ! -f $SELFPATH/git-2.9.5.tar.gz ];then
		wget https://www.kernel.org/pub/software/scm/git/git-2.9.5.tar.gz
	fi
	tar zxvf git-2.9.5.tar.gz
	cd git-2.9.5
	make configure
    ./configure --prefix=/usr/local/git --with-iconv=/usr/local/libiconv
    make all doc
    make install install-doc install-html
    echo "export PATH=$PATH:/usr/local/git/bin" >> /etc/bashrc
    source /etc/bashrc
	ln -s /usr/local/git/bin/* /usr/bin/
	rm -rf $SELFPATH/git-2.9.5
}

# 卸载git
unstall_git(){
	rm -rf /usr/local/git
	rm -rf /usr/local/git/bin/git
	rm -rf /usr/local/git/bin/git-cvsserver
	rm -rf /usr/local/git/bin/gitk
	rm -rf /usr/local/git/bin/git-receive-pack
	rm -rf /usr/local/git/bin/git-shell
	rm -rf /usr/local/git/bin/git-upload-archive
	rm -rf /usr/local/git/bin/git-upload-pack
}


# 安装go
install_go(){
	cd $SELFPATH
	uninstall_go
	# 动态链接库，用于下面的判断条件生效
	ldconfig
	# 判断操作系统位数下载不同的安装包
	if [ $(getconf WORD_BIT) = '32' ] && [ $(getconf LONG_BIT) = '64' ];then
		# 判断文件是否已经存在
		if [ ! -f $SELFPATH/go1.9.1.linux-amd64.tar.gz ];then
			wget https://www.golangtc.com/static/go/1.9.1/go1.9.1.linux-amd64.tar.gz
		fi
	    tar zxvf go1.9.1.linux-amd64.tar.gz
	else
		if [ ! -f $SELFPATH/go1.9.1.linux-386.tar.gz ];then
			wget https://www.golangtc.com/static/go/1.9.1/go1.9.1.linux-386.tar.gz
		fi
	    tar zxvf go1.9.1.linux-386.tar.gz
	fi
	mv go /usr/local/
	ln -s /usr/local/go/bin/* /usr/bin/
}

# 卸载go

uninstall_go(){
	rm -rf /usr/local/go
	rm -rf /usr/bin/go
	rm -rf /usr/bin/godoc
	rm -rf /usr/bin/gofmt
}

# 安装ngrok
install_ngrok(){
	uninstall_ngrok
	cd /usr/local
	if [ ! -f /usr/local/ngrok ];then
		cd /usr/local/
		git clone https://github.com/tutumcloud/ngrok.git
	fi
	export GOPATH=/usr/local/ngrok/
	export NGROK_DOMAIN=$DOMAIN
	cd ngrok
	openssl genrsa -out rootCA.key 2048
	openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$NGROK_DOMAIN" -days 5000 -out rootCA.pem
	openssl genrsa -out server.key 2048
	openssl req -new -key server.key -subj "/CN=$NGROK_DOMAIN" -out server.csr
	openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.crt -days 5000
	cp rootCA.pem assets/client/tls/ngrokroot.crt
	cp server.crt assets/server/tls/snakeoil.crt
	cp server.key assets/server/tls/snakeoil.key
	#替换下载源地址,如果是在天朝的服务器需要改,香港或者国外的服务器不需要
	#sed -i 's#code.google.com/p/log4go#github.com/keepeye/log4go#' /usr/local/ngrok/src/ngrok/log/logger.go
	#编译服务端和客户端
	GOOS=`go env | grep GOOS | awk -F\" '{print $2}'`
    GOARCH=`go env | grep GOARCH | awk -F\" '{print $2}'`
	cd /usr/local/go/src
	GOOS=$GOOS GOARCH=$GOARCH ./make.bash
	cd /usr/local/ngrok
	GOOS=$GOOS GOARCH=$GOARCH make release-server
	echo "启动服务端"
	/usr/local/ngrok/bin/ngrokd -domain=$NGROK_DOMAIN -httpAddr=":8081" -httpsAddr=":8082" -tunnelAddr=":8083"
}

# 卸载ngrok
uninstall_ngrok(){
	rm -rf /usr/local/ngrok
}

# 编译客户端
compile_client(){
	cd /usr/local/go/src
	GOOS=$1 GOARCH=$2 ./make.bash
	cd /usr/local/ngrok/
	GOOS=$1 GOARCH=$2 make release-client
}

# 生成客户端
client(){
	echo "1、Linux 32位"
	echo "2、Linux 64位"
	echo "3、Windows 32位"
	echo "4、Windows 64位"
	echo "5、Mac OS 32位"
	echo "6、Mac OS 64位"
	echo "7、Linux ARM"

	read num
	case "$num" in
		[1] )
			compile_client linux 386
		;;
		[2] )
			compile_client linux amd64
		;;
		[3] )
			compile_client windows 386
		;;
		[4] )
			compile_client windows amd64
		;;
		[5] )
			compile_client darwin 386
		;;
		[6] )
			compile_client darwin amd64
		;;
		[7] )
			compile_client linux arm
		;;
		*) echo "选择错误，退出";;
	esac

}

echo "------------------------"
echo "1、全新安装"
echo "2、安装依赖"
echo "3、安装git"
echo "4、安装go环境"
echo "5、安装ngrok"
echo "6、生成客户端"
echo "7、卸载"
echo "8、启动服务"
echo "9、查看配置文件"
echo "------------------------"
read num
case "$num" in
	[1] )
		install_yilai
		install_git
		install_go
		install_ngrok
	;;
	[2] )
		install_yilai
	;;
	[3] )
		install_git
	;;
	[4] )
		install_go
	;;
	[5] )
		install_ngrok
	;;
	[6] )
		client
	;;
	[7] )
		unstall_git
		uninstall_go
		uninstall_ngrok
	;;
	[8] )
		echo "输入启动域名"
		read domain
	         echo "httpAddr"
		read port1
                  echo "httpsAddr"
		read port2
                  echo "tunnelAddr"
		read port3
		nohup /usr/local/ngrok/bin/ngrokd -domain=$DOMAIN -httpAddr=":$port1" -httpsAddr=":$port2" -tunnelAddr=":$port3" -log="none" &
	;;
	[9] )
		echo "输入启动域名"
		read domain
                  echo "tunnelAddr"
		read port
		echo server_addr: '"'$domain:$port'"'
		echo "trust_host_root_certs: false"

	;;
	*) echo "";;
esac
