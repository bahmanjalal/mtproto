# mtproxy

MTProxyTLS一Key install green script




## Installation method 

Execute the following code to install 

```bash
mkdir /home/mtproxy && cd /home/mtproxy
curl -s -o mtproxy.sh https://raw.githubusercontent.com/ellermister/mtproxy/master/mtproxy.sh && chmod +x mtproxy.sh && bash mtproxy.sh
```

 ![mtproxy.sh](https://raw.githubusercontent.com/ellermister/mtproxy/master/mtproxy.jpg)
 
 ## whitelist MTProxy Docker 
The image integrates nginx and mtproxy+tls to disguise traffic, and uses a whitelist mode to deal with firewall detection.

 ```bash
secret=$(head -c 16 /dev/urandom | xxd -ps)
domain="cloudflare.com"
docker run --name nginx-mtproxy -d -e secret="$secret" -e domain="$domain" -p 8080:80 -p 8443:443 ellermister/nginx-mtproxy:latest
 ```
For more use, please refer to ： https://hub.docker.com/r/ellermister/nginx-mtproxy



## How to use 

Run the service 

```bash
bash mtproxy.sh start
```

Debuging

```bash
bash mtproxy.sh debug
```

Stop service 

```bash
bash mtproxy.sh stop
```

Restart service 

```bash
bash mtproxy.sh restart
```



## Uninstall and install 

Because it is a green version, the uninstallation is extremely simple, just delete the directory you are in. 

```bash
rm -rf /home/mtproxy
```



## boot

Boot script, if your rc.local file does not exist, please check the boot service. 

Add the following code to the boot script by editing the file `/etc/rc.local` ：

```bash
cd /home/mtproxy && bash mtproxy.sh start > /dev/null 2>&1 &
```

