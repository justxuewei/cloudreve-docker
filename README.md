# Cloudreve Docker

此Docker镜像由Xavier Niu维护。

优势

- 基于最新的Cloudreve V3
- 长期维护
- 镜像体积小
- 支持多种架构
- 安装简单
- 内含详细的Cloudreve+Caddy+Aria2部署教程

支持架构

- linux/amd64: `xaiverniu/cloudreve:latest`
- linux/arm64: `xaiverniu/cloudreve:arm64v8`
- linux/arm/v7: `xaiverniu/cloudreve:arm32v7`

基于

- cloudreve: 3.0.0-rc1
- base image
  - latest: golang:1.14.1-alpine3.11(builder), lsiobase/alpine:3.11(runtime)
  - arm64v8: arm64v8/golang:1.14.1-alpine3.11(builder), lsiobase/alpine:arm64v8-3.11(runtime)
  - arm32v7: arm32v7/golang:1.14.1-alpine3.11(builder), lsiobase/alpine:arm32v7-3.11(runtime)

## Cloudreve

Cloudreve能助您以最低的成本快速搭建公私兼备的网盘系统。

官方网站：https://cloudreve.org

GitHub：https://github.com/cloudreve/Cloudreve

## 运行

运行模式

- OC: 仅Cloudreve
- CAC: Caddy反代+Aria2离线下载服务+Cloudreve

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

> ⚠️注意：此教程仅在linux/amd64架构测试，如果您正在使用arm架构，部分参数请根据实际情况调整。

前提条件

- 已安装docker，如果没有请执行`wget -qO- https://get.docker.com/ | bash`安装docker。
- 一个域名并解析到运行Cloudreve的服务器，这里以`https://cloudreve.example.com`为例。

Step1. 创建Network

```bash
docker network create my-network
```

Step2. 创建Caddy配置文件

```bash
mkdir -p /dockercnf/caddy \
	&& vim /dockercnf/caddy/Caddyfile
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

Step3. 启动Caddy服务

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

Step4. 启动Aria2服务（如不需要离线下载功能该步骤略过）

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
- `<SECRET>`: Aria2 RPC密码（你可以去[这里](https://miniwebtool.com/zh-cn/random-string-generator/)生成随机字符串），请记下该密码，在后续Cloudreve设置Aria2中会使用
- `<PATH TO CONFIG>`: Aria2的配置文件夹，例如`/dockercnf/aria2/conf`
- `<PATH TO TEMP>`: 临时下载文件夹，需要与Cloudreve的`/downloads`对应，例如`/dockercnf/aria2/temp`
- 如果不需要外网访问Aria2可以将`#1`所在行删除

需要额外编辑Aria2的配置文件以达到最好的效果（部分参数请根据自己实际情况调整），执行`vim /dockercnf/aria2/config/aria2.conf`

```
# 最大同时下载任务数
max-concurrent-downloads=5
# 同一服务器连接数
max-connection-per-server=2
# 注意：force-save设置为true可能会导致重启镜像后已完成的任务重复下载，最终占用存储空间
force-save=false
```

Step5. 预创建Cloudreve的数据库和配置文件，这里以`/dockercnf/cloudreve`为cloudreve配置目录

```bash
mkdir -p /dockercnf/cloudreve \
	&& touch /dockercnf/cloudreve/conf.ini \
	&& touch /dockercnf/cloudreve/cloudreve.db
```

Step6. 启动Cloudreve

```bash
docker run -d \
  --name cloudreve \
  -e PUID=1000 \ # optional
  -e PGID=1000 \ # optional
  -e TZ="Asia/Shanghai" \ # optional
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

- `<PATH TO UPLOADS>`:上传目录, 例如`/sharedfolders`
- `<PATH TO TEMP>`: 临时下载文件夹，需要与Aria的`/downloads`对应，例如`/dockercnf/aria2/temp`（如不需要离线下载功能`#1`可以删除）
- `<PATH TO conf.ini>`: 配置文件，如`/dockercnf/cloudreve/conf.ini`
- ` <PATH TO cloudreve.db>`: 数据库文件，如`/dockercnf/cloudreve/cloudreve.db`

Step7. 配置Cloudreve连接Aria2服务器

- 以管理员身份登陆
- 点击"头像（右上角） > 管理面板"
- 点击"参数设置 > 离线下载"

  - RPC服务器地址: http://aria2:6800/
  - RPC Secret: 参见`启动Aria2服务`中的`<SECRET>`
  - 临时下载地址: /downloads
  - 其他选项按照默认值即可
- 测试连接并保存

## 有疑问？

如果有任何问题可以在GitHub中创建一个新的issue或者通过邮件`a#nxw.name`与我取得联系。