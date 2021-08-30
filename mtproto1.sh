#!/bin/bash
WORKDIR=$(dirname $(readlink -f $0))
cd $WORKDIR
pid_file=$WORKDIR/pid/pid_mtproxy

check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /etc/issue; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /proc/version; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /proc/version; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ "${checkType}" == "sysRelease" ]]; then
        if ["${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == "packageManager" ]]; then
        if ["${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

function pid_exists(){
  local exists=`ps aux | awk'{print $2}'| grep -w $1`
  if [[! $exists ]]
  then
    return 0;
  else
    return 1;
  fi
}

install(){
  cd $WORKDIR
  if [! -d "./pid" ]; then
    mkdir "./pid"
  fi

  xxd_status=1
  echo a|xxd -ps &> /dev/null
  if [$? != "0" ]; then
    xxd_status=0
  fi

  if [[ "`uname -m`" != "x86_64" ]]; then
    if check_sys packageManager yum; then
      yum install -y openssl-devel zlib-devel iproute
      yum groupinstall -y "Development Tools"
      if [$xxd_status == 0 ]; then
        yum install -y vim-common
      fi
    elif check_sys packageManager apt; then
      apt-get -y update
      apt install -y git curl build-essential libssl-dev zlib1g-dev iproute2
      if [$xxd_status == 0 ]; then
        apt install -y vim-common
      fi
    fi
  else
    if check_sys packageManager yum && [$xxd_status == 0 ]; then
      yum install -y vim-common
    elif check_sys packageManager apt && [$xxd_status == 0 ]; then
      apt-get -y update
      apt install -y vim-common
    fi
  fi

  if [[ "`uname -m`" != "x86_64" ]]; then
    if [! -d'MTProxy' ]; then
      git clone https://github.com/TelegramMessenger/MTProxy
    fi;
    cd MTProxy
    make && cd objs/bin
    cp -f $WORKDIR/MTProxy/objs/bin/mtproto-proxy $WORKDIR
    cd $WORKDIR
  else
    wget https://github.com/ellermister/mtproxy/releases/download/0.02/mtproto-proxy -O mtproto-proxy -q
    chmod +x mtproto-proxy
  fi
}


print_line(){
  echo -e "========================================"
}


config_mtp(){
  cd $WORKDIR
  echo -e "Detected that your configuration file does not exist, and guide you to generate it!" && print_line
  while true
  do
  default_port=443
  echo -e "Please enter a client connection port [1-65535]"
  read -p "(default port: ${default_port}):" input_port
  [-z "${input_port}"] && input_port=${default_port}
  expr ${input_port} + 1 &>/dev/null
  if [$? -eq 0 ]; then
      if [${input_port} -ge 1] && [${input_port} -le 65535] && [${input_port:0:1} != 0 ]; then
          echo
          echo "---------------------------"
          echo "port = ${input_port}"
          echo "---------------------------"
          echo
          break
      fi
  fi
  echo -e "[\033[33m error\033[0m] Please re-enter a client connection port [1-65535]"
  done

  # Management port
  while true
  do
  default_manage=8888
  echo -e "Please enter a management port [1-65535]"
  read -p "(default port: ${default_manage}):" input_manage_port
  [-z "${input_manage_port}"] && input_manage_port=${default_manage}
  expr ${input_manage_port} + 1 &>/dev/null
  if [$? -eq 0] && [$input_manage_port -ne $input_port ]; then
      if [${input_manage_port} -ge 1] && [${input_manage_port} -le 65535] && [${input_manage_port:0:1} != 0 ]; then
          echo
          echo "---------------------------"
          echo "manage port = ${input_manage_port}"
          echo "---------------------------"
          echo
          break
      fi
  fi
  echo -e "[\033[33m error\033[0m] Please re-enter a management port [1-65535]"
  done

  # domain
  while true
  do
  default_domain="google.com"
  echo -e "Please enter a domain name that needs to be disguised:"
  read -p "(default domain name: ${default_domain}):" input_domain
  [-z "${input_domain}"] && input_domain=${default_domain}
  http_code=$(curl -I -m 10 -o /dev/null -s -w %{http_code} $input_domain)
  if [$http_code -eq "200"] || [$http_code -eq "302"] || [$http_code -eq "301" ]; then
    echo
    echo "---------------------------"
    echo "Disguise domain name = ${input_domain}"
    echo "---------------------------"
    echo
    break
  fi
  echo -e "[\033[33m status code: ${http_code} error\033[0m] The domain name cannot be accessed, please re-enter or change the domain name!"
  done
  
   # config info
  public_ip=$(curl -s https://api.ip.sb/ip --ipv4)
  [-z "$public_ip"] && public_ip=$(curl -s ipinfo.io/ip --ipv4)
  secret=$(head -c 16 /dev/urandom | xxd -ps)

  # proxy tag
  while true
  do
  default_tag=""
  echo -e "Please enter the TAG you need to promote:"
  echo -e "If not, please contact @MTProxybot to further create your TAG, you may need the following information:"
  echo -e "IP: ${public_ip}"
  echo -e "PORT: ${input_port}"
  echo -e "SECRET (you can fill in casually): ${secret}"
  read -p "(leave blank to skip):" input_tag
  [-z "${input_tag}"] && input_tag=${default_tag}
  if [-z "$input_tag"] || [[ "$input_tag" =~ ^[A-Za-z0-9]{32}$ ]]; then
    echo
    echo "---------------------------"
    echo "PROXY TAG = ${input_tag}"
    echo "---------------------------"
    echo
    break
  fi
  echo -e "[\033[33m error\033[0m] TAG format is incorrect!"
  done

  curl -s https://core.telegram.org/getProxySecret -o proxy-secret
  curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
  cat >./mtp_config <<EOF
#!/bin/bash
secret="${secret}"
port=${input_port}
web_port=${input_manage_port}
domain="${input_domain}"
proxy_tag="${input_tag}"
EOF
  echo -e "The configuration has been generated!"
}

status_mtp(){
  if [-f $pid_file ]; then
    pid_exists `cat $pid_file`
    if [[ $? == 1 ]]; then
      return 1
    fi
  fi
  return 0
}

info_mtp(){
  status_mtp
  if [$? == 1 ]; then
    source ./mtp_config
    public_ip=$(curl -s https://api.ip.sb/ip --ipv4)
    [-z "$public_ip"] && public_ip=$(curl -s ipinfo.io/ip --ipv4)
    domain_hex=$(xxd -pu <<< $domain | sed's/0a//g')
    client_secret="ee${secret}${domain_hex}"
    echo -e "TMProxy+TLS proxy: \033[32m running\033[0m"
    echo -e "Server IP: \033[31m$public_ip\033[0m"
    echo -e "Server port: \033[31m$port\033[0m"
    echo -e "MTProxy Secret: \033[31m$client_secret\033[0m"
    echo -e "TG one-key link: https://t.me/proxy?server=${public_ip}&port=${port}&secret=${client_secret}"
    echo -e "TG one-key link: tg://proxy?server=${public_ip}&port=${port}&secret=${client_secret}"
  else
    echo -e "TMProxy+TLS proxy: \033[33m has stopped\033[0m"
  fi
}


run_mtp(){
  cd $WORKDIR
  status_mtp
  if [$? == 1 ]; then
    echo -e "Reminder: \033[33mMTProxy is already running, please do not run it again!\033[0m"
  else
    curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
    source ./mtp_config
    nat_ip=$(echo $(ip a | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk'{print $2}' | cut -d "/" -f1 |awk'NR==1 {print $1}'))
    public_ip=`curl -s https://api.ip.sb/ip --ipv4`
    [-z "$public_ip"] && public_ip=$(curl -s ipinfo.io/ip --ipv4)
    nat_info=""
    if [[ $nat_ip != $public_ip ]]; then
      nat_info="--nat-info ${nat_ip}:${public_ip}"
    fi
    tag_arg=""
    [[ -n "$proxy_tag" ]] && tag_arg="-P $proxy_tag"
    ./mtproto-proxy -u bahtah -p $web_port -H $port -S $secret --aes-pwd proxy-secret proxy-multi.conf -M 1 $tag_arg --domain $domain $nat_info >/dev/null 2>&1 &
    
    echo $!>$pid_file
    sleep 2
    info_mtp
  fi
}

debug_mtp(){
  cd $WORKDIR
  source ./mtp_config
  nat_ip=$(echo $(ip a | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk'{print $2}' | cut -d "/" -f1 |awk'NR==1 {print $1}'))
  public_ip=`curl -s https://api.ip.sb/ip --ipv4`
  [-z "$public_ip"] && public_ip=$(curl -s ipinfo.io/ip --ipv4)
  nat_info=""
  if [[ $nat_ip != $public_ip ]]; then
      nat_info="--nat-info ${nat_ip}:${public_ip}"
  fi
  tag_arg=""
  [[ -n "$proxy_tag" ]] && tag_arg="-P $proxy_tag"
  echo "The debugging mode is currently running:"
  echo -e "\tYou can use Ctrl+C to cancel the operation at any time"
  echo "./mtproto-proxy -u bahtah -p $web_port -H $port -S $secret --aes-pwd proxy-secret proxy-multi.conf -M 1 $tag_arg --domain $domain $nat_info"
  ./mtproto-proxy -u bahtah -p $web_port -H $port -S $secret --aes-pwd proxy-secret proxy-multi.conf -M 1 $tag_arg --domain $domain $nat_info
}

stop_mtp(){
  local pid=`cat $pid_file`
  kill -9 $pid
  pid_exists $pid
  if [[ $pid == 1 ]]
  then
    echo "Failed to stop the task"
  fi
}

fix_mtp(){
  if [`id -u` != 0 ]; then
    echo -e "> ※ (This function can only be executed by root users)"
  fi

  
  print_line
  echo -e "> Start to install/update iproute2..."
  print_line
  
  if check_sys packageManager yum; then
    yum install -y epel-release
    yum update -y
yum install -y iproute
  elif check_sys packageManager apt; then
    apt-get install -y epel-release
    apt-get update -y
apt-get install -y iproute2
  fi
  
  echo -e "< Processing is complete, if there is an error, ignore it..."
  echo -e "<If you encounter port conflicts, please close related programs by yourself"
}



param=$1
if [[ "start" == $param ]]; then
  echo "Coming soon: start script";
  run_mtp
elif [[ "stop" == $param ]]; then
  echo "About to: stop the script";
  stop_mtp;
elif [[ "debug" == $param ]]; then
  echo "Coming soon: debug and run";
  debug_mtp;
elif [[ "restart" == $param ]]; then
  stop_mtp
  run_mtp
elif [[ "fix" == $param ]]; then
  fix_mtp
fi 
