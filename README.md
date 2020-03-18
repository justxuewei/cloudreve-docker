# Cloudreve Docker

此Docker镜像由Xavier Niu维护，基于：

- lsiobase/alpine:3.11
- golang: 1.14
- cloudreve: 3.0.0-rc1

该Docker镜像使用[xavier-niu/build-cloudreve-docker-action@master](https://github.com/xavier-niu/build-cloudreve-docker-action)编译Cloudreve源文件，将编译后的二进制文件拷贝至纯净alpine系统中，整个镜像体积不到20M。

## Cloudreve

Cloudreve能助您以最低的成本快速搭建公私兼备的网盘系统。

官方网站：https://cloudreve.org

Github：https://github.com/cloudreve/Cloudreve

## 运行

运行模式

- OC: 仅Cloudreve
- CAC: Caddy反带+Aria2离线下载服务+Cloudreve

### OC

```bash
docker run -d \
  --name cloudreve \
  -e PUID=1000 \ # optional
  -e PGID=1000 \ # optional
  -e TZ="Asia/Shanghai" \ # optional
  -p 5212:5212 \ 
  --restart=unless-stopped \
  -v <PATH TO UPLOADS>:/cloudreve/uploads \
  -v <PATH TO conf.ini>:/cloudreve/conf.ini \
  -v <PATH TO cloudreve.db>:/cloudreve/cloudreve.db \
  xavierniu/cloudreve
```

注意

- 首次启动后请执行`docker logs -f cloudreve`获取初始密码

环境变量

- PUID以及PGID的使用方法以及为什么使用参见: [Understanding PUID and PGID](https://docs.linuxserver.io/general/understanding-puid-and-pgid)
- `TZ`设置时区，默认值为`Asia/Shanghai`

Volumes

- `<PATH TO UPLOADS>`:上传目录
- `<PATH TO conf.ini>`: 配置文件
- ` <PATH TO cloudreve.db>`: 数据库文件

### CAC

前提条件

- 一个域名并解析到服务器，这里以`https://cloudreve.example.com`为例

创建Network

```bash
docker network create my-network
```

创建Caddy配置文件

```bash
mkdir -p /dockercnf/caddy \
	&& vim /docker/caddy/Caddyfile
```

填入以下信息

```
cloudreve.example.com {
  tls admin@example.com
  proxy / cloudreve:5212 {
    transparent
  }
}
```

接下来启动Caddy服务

```bash
docker run -d \
  --name caddy \
  -e "ACME_AGREE=true" \
  -e "CADDYPATH=/etc/caddycerts" \
  -v /dockercnf/caddy/certs:/etc/caddycerts \
  -v /dockercnf/caddy/Caddyfile:/etc/Caddyfile \
  --network my-network \
  -p 80:80 -p 443:443 \
  --restart unless-stopped \
  abiosoft/caddy
```

启动Aria2服务（如不需要离线下载功能该步骤略过）

```bash
docker run -d --name=aria2 \
  -e PUID=1000 -e PGID=1000 \
  -e TZ=Asia/Shanghai \
  -e SECRET=<SECRET> \
  -e CACHE=512M \
  -e UpdateTracker=true \
  -e QUIET=true \
  -p 6881:6881 -p 6881:6881/udp \
  -p 6800:6800 \ #1
  --network my-network \
  -v <PATH TO CONFIG>:/config \
  -v <PATH TO TEMP>:/downloads \
  --restart unless-stopped \
  superng6/aria2
```

说明

- PUID以及PGID的使用方法以及为什么使用参见: [Understanding PUID and PGID](https://docs.linuxserver.io/general/understanding-puid-and-pgid)

- `<PATH TO CONFIG>`: Aria2的配置文件夹
- `<PATH TO TEMP>`: 临时下载文件夹，需要与Cloudreve的`/downloads`对应
- 如果不需要外网访问Aria2可以将`#1`所在行删除

预创建Cloudreve的数据库和配置文件，这里以`/dockercnf/cloudreve`为cloudreve配置目录

```bash
mkdir -p /dockercnf/cloudreve \
	&& touch /dockercnf/cloudreve/conf.ini \
	&& touch /dockercnf/cloudreve/cloudreve.db
```

启动Cloudreve

```bash
docker run -d \
  --name cloudreve \
  -e PUID=1000 \ # optional
  -e PGID=1000 \ # optional
  -e TZ="Asia/Shanghai" \ # optional
  -p 5212:5212 \ 
  --network my-network \
  --restart=unless-stopped \
  -v <PATH TO UPLOADS>:/cloudreve/uploads \
  -v <PATH TO TEMP>:/downloads \ #1
  -v <PATH TO conf.ini>:/cloudreve/conf.ini \
  -v <PATH TO cloudreve.db>:/cloudreve/cloudreve.db \
  xavierniu/cloudreve
```

说明

- 首次启动后请执行`docker logs -f cloudreve`获取初始密码

- PUID以及PGID的使用方法以及为什么使用参见: [Understanding PUID and PGID](https://docs.linuxserver.io/general/understanding-puid-and-pgid)

- `<PATH TO UPLOADS>`:上传目录
- `<PATH TO TEMP>`: 临时下载文件夹，需要与Aria的`/downloads`对应（如不需要离线下载功能`#1`可以删除）
- `<PATH TO conf.ini>`: 配置文件
- ` <PATH TO cloudreve.db>`: 数据库文件

配置Cloudreve

- 以管理员身份登陆

- 依次点击"参数设置 > 离线下载"，按照图示设置即可

  ![cloudreve](http://res.niuxuewei.com/2020-03-18-075910.jpg)