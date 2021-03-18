# Cloudreve Docker

![](https://img.shields.io/github/workflow/status/xavier-niu/cloudreve-docker/Publish%20Docker) ![](https://img.shields.io/badge/cloudreve-3.3.0-brightgreen) ![](https://img.shields.io/docker/image-size/xavierniu/cloudreve/latest) ![](https://img.shields.io/docker/pulls/xavierniu/cloudreve) ![](https://img.shields.io/badge/maintainer-xavierniu-lightgrey)

优势

- 基于最新的Cloudreve V3
- 长期维护
- 镜像体积小
- 纯净安装，无多余组件
- 支持多种架构(amd64, arm64, arm32/v7)
- 简易安装
- 内含详细的Cloudreve+Nginx+Aria2部署教程

## Cloudreve

Cloudreve能助您以最低的成本快速搭建公私兼备的网盘系统。

官方网站：https://cloudreve.org

GitHub：https://github.com/cloudreve/Cloudreve

## 开始

运行模式

> ⚠️注意1：由于Caddy v1已停止维护，故支持文档将原有CAC模式变更为NAC模式，即使用Nginx作为反代服务器。目前这项改变尚处于测试阶段，还无法保证NAC模式和Docker Compose方式配置的正确性。如果有任何疑问，请直接提出issue。
> 
> ⚠️注意2：本教程Nginx配置默认不开启TLS(HTTPS)。如果有相关需求，请将证书保存至Nginx的`ssl`目录并修改Nginx的配置文件。这部分配置工作不在本教程覆盖范围内，因此不会为此提供支持。

- [Cloudreve Docker](#cloudreve-docker)
  - [Cloudreve](#cloudreve)
  - [开始](#开始)
    - [获取PUID和PGID](#获取puid和pgid)
    - [Docker Run方式运行](#docker-run方式运行)
      - [OC](#oc)
      - [NAC](#nac)
    - [Docker Compose方式运行](#docker-compose方式运行)
  - [升级](#升级)
  - [有疑问？](#有疑问)

### 获取PUID和PGID

为什么要使用PUID和PGID参见: [Understanding PUID and PGID](https://docs.linuxserver.io/general/understanding-puid-and-pgid)

假设当前登陆用户为`root`，则执行

```bash
id root
```

就会得到类似于下面的一段代码

```
uid=1000(root) gid=1001(root)
```

则PUID填入1000，PGID填入1001

### Docker Run方式运行

#### OC

预创建Cloudreve的数据库和配置文件，这里以`/dockercnf/cloudreve`为cloudreve配置目录。

```bash
mkdir -p /dockercnf/cloudreve \
	&& touch /dockercnf/cloudreve/conf.ini \
	&& touch /dockercnf/cloudreve/cloudreve.db
```

启动容器

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
  -v <PATH TO avatar>:/cloudreve/avatar \
  xavierniu/cloudreve
```

说明

- 首次启动后请执行`docker logs -f cloudreve`获取初始密码
- PUID以及PGID的获取方式详见`获取PUID和PGID`
- `TZ`设置时区，默认值为`Asia/Shanghai`
- `<PATH TO UPLOADS>`:上传目录, 例如`/sharedfolders`
- `<PATH TO conf.ini>`: 配置文件，如`/dockercnf/cloudreve/conf.ini`（注意这里是挂载的文件，而非文件夹）
- ` <PATH TO cloudreve.db>`: 数据库文件，如`/dockercnf/cloudreve/cloudreve.db`（注意这里是挂载的文件，而非文件夹）
- ` <PATH TO avatar>`: 头像文件夹，如`/dockercnf/cloudreve/avatar`

#### NAC

> ⚠️注意：此教程仅在linux/amd64架构测试，如果您正在使用arm架构，部分参数请根据实际情况调整。

前提

- 已安装docker，如果没有请执行`wget -qO- https://get.docker.com/ | bash`安装docker。
- 一个域名并解析到运行Cloudreve的服务器，这里以`cloudreve.example.com`为例。

**Step1. 创建Network**

```bash
docker network create my-network
```

**Step2. 创建Nginx配置文件**

```bash
mkdir -p /dockercnf/nginx/conf.d \
  && mkdir -p /dockercnf/nginx/ssl \
	&& vim /dockercnf/nginx/conf.d/cloudreve.conf
```

填入以下信息

```
server {
  listen 80;
  location / {
    proxy_pass http://cloudreve:5212;
    proxy_set_header Host $host;
  }
}
```

**Step3. 启动Nginx服务**

```bash
docker run -d \
  --name nginx \
  -v /dockercnf/nginx/conf.d:/etc/nginx/conf.d \
  -v /dockercnf/nginx/ssl:/etc/nginx/ssl \
  --network my-network \
  -p 80:80 -p 443:443 \
  --restart unless-stopped \
  nginx:alpine
```

**Step4. 启动Aria2服务（如不需要离线下载功能该步骤略过）**

```bash
docker run -d \
    --name aria2 \
    --restart unless-stopped \
    --log-opt max-size=1m \
    -e PUID=1000 \
    -e PGID=1000 \
    -e RPC_SECRET=<SECRET> \
    -p 6800:6800 \ #1
    -p 6888:6888 -p 6888:6888/udp \
    --network my-network \
    -v <PATH TO CONFIG>:/config \
    -v <PATH TO TEMP>:/downloads \
    p3terx/aria2-pro
```

说明

- PUID以及PGID的获取方式详见`获取PUID和PGID`。
- `<SECRET>`: Aria2 RPC密码（你可以去[这里](https://miniwebtool.com/zh-cn/random-string-generator/)生成随机字符串）。请记下该密码！在后续Cloudreve设置Aria2中会使用。
- `<PATH TO CONFIG>`: Aria2的配置文件夹，例如`/dockercnf/aria2/conf`。
- `<PATH TO TEMP>`: 临时下载文件夹，需要与Cloudreve的`/downloads`对应，例如`/dockercnf/aria2/temp`。
- 如果不需要外网访问Aria2可以将`#1`所在行删除。

**Step5. 预创建Cloudreve的数据库和配置文件，这里以`/dockercnf/cloudreve`为cloudreve配置目录**

```bash
mkdir -p /dockercnf/cloudreve \
	&& touch /dockercnf/cloudreve/conf.ini \
	&& touch /dockercnf/cloudreve/cloudreve.db
```

**Step6. 启动Cloudreve**

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
  -v <PATH TO avatar>:/cloudreve/avatar \ 
  xavierniu/cloudreve
```

说明

- 首次启动后请执行`docker logs -f cloudreve`获取初始密码

- PUID以及PGID的获取方式详见`获取PUID和PGID`

- `<PATH TO UPLOADS>`:上传目录, 例如`/sharedfolders`
- `<PATH TO TEMP>`: 临时下载文件夹，需要与Aria的`/downloads`对应，例如`/dockercnf/aria2/temp`（如不需要离线下载功能`#1`可以删除）
- `<PATH TO conf.ini>`: 配置文件，如`/dockercnf/cloudreve/conf.ini`
- ` <PATH TO cloudreve.db>`: 数据库文件，如`/dockercnf/cloudreve/cloudreve.db`
- ` <PATH TO avatar>`: 头像文件夹，如`/dockercnf/cloudreve/avatar`

**Step7. 配置Cloudreve连接Aria2服务器**

- 以管理员身份登陆
- 点击"头像（右上角） > 管理面板"
- 点击"参数设置 > 离线下载"

  - RPC服务器地址: http://aria2:6800/
  - RPC Secret: 参见`启动Aria2服务`中的`<SECRET>`
  - 临时下载地址: /downloads
  - 其他选项按照默认值即可
- 测试连接并保存

### Docker Compose方式运行

> ⚠️注意：该docker-compose文件仅适用于linux/amd64架构，如果您正在使用arm请尝试修改部分参数。

前提

- 已安装docker，如果没有请执行`wget -qO- https://get.docker.com/ | bash`安装docker。
- 已安装docker compose，如果没有请参考[Install Docker Compose](https://docs.docker.com/compose/install/)。
- 一个域名并解析到运行Cloudreve的服务器，这里以`cloudreve.example.com`为例。
- 确保80和443端口没有被占用，如果您已经有服务器软件（如Nginx或Caddy），请考虑为原有服务器软件增加配置文件并删除docker compose配置文件中的caddy容器。

**Step1. 预创建文件**

Nginx配置文件

```bash
mkdir -p /dockercnf/nginx/conf.d \
  && mkdir -p /dockercnf/nginx/ssl \
	&& vim /dockercnf/nginx/conf.d/cloudreve.conf
```

填入以下信息

```
server {
  listen 80;
  location / {
    proxy_pass http://cloudreve:5212;
    proxy_set_header Host $host;
  }
}
```

Cloudreve配置文件及数据库文件

```bash
mkdir -p /dockercnf/cloudreve \
	&& touch /dockercnf/cloudreve/conf.ini \
	&& touch /dockercnf/cloudreve/cloudreve.db
```

**Step2. 下载环境文件以及Docker Compose文件**

下载环境文件

```bash
wget -qO- https://raw.githubusercontent.com/xavier-niu/cloudreve-docker/master/docker-compose-env-example > .env
```

根据需要对环境变量进行修改

- 必填项
  - CLOUDREVE_PUID: PUID的获取方式详见`获取PUID和PGID`
  - CLOUDREVE_PGID: PGID的获取方式详见`获取PUID和PGID`
  - ARIA2_RPC_SECRET: Aria2 RPC密码（你可以去[这里](https://miniwebtool.com/zh-cn/random-string-generator/)生成随机字符串）。请记下该密码！在后续Cloudreve设置Aria2中会使用。
- 选填项（如无特殊需要不建议修改）
  - TEMP_FOLDER_PATH: 离线下载临时文件夹路径
  - ARIA2_CONFIG_PATH: Aria2的配置文件夹路径
  - CLOUDREVE_UPLOAD_PATH: Cloudreve上传文件夹路径
  - CLOUDREVE_CONF_INI_PATH: Cloudreve配置文件路径
  - CLOUDREVE_DB_PATH: Cloudreve数据库文件路径

下载Docker Compose文件

```bash
wget -qO- https://raw.githubusercontent.com/xavier-niu/cloudreve-docker/master/docker-compose-amd64.yml > docker-compose.yml
```

**Step3. 启动Docker Compose**

```bash
docker-compose up -d
```

说明

- Aria2-RPC会暴露于外网，访问端口`6800`，Secret为你对`ARIA2_RPC_SECRET`设置的随机字符串。

**Step4. 配置Cloudreve连接Aria2服务器**

- 以管理员身份登陆
- 点击"头像（右上角） > 管理面板"
- 点击"参数设置 > 离线下载"

  - RPC服务器地址: `http://aria2:6800/`
  - RPC Secret: 你对`ARIA2_RPC_SECRET`设置的随机字符串
  - 临时下载地址: `/downloads`
  - 其他选项按照默认值即可
- 测试连接并保存

## 升级

首先请暂停并移除正在运行的容器并从DockerHub拉取最新的镜像

```bash
docker stop cloudreve \
  && docker rm cloudreve \
  && docker pull xavierniu/cloudreve
```

重复上面的运行步骤再次启动容器即可。

## 有疑问？

如果有任何问题可以在GitHub中创建一个新的issue或者通过邮件`a#nxw.name`与我取得联系。
