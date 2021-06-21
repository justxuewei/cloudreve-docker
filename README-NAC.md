# Cloudreve Docker - NAC

NAC模式（Nginx+Aria2+Cloudreve），即启动Cloudreve，同时使用Nginx作为反向代理服务器以及Aria2作为离线下载服务（可选）。此教程仅在linux/amd64架构测试，如果您正在使用arm架构，部分参数请根据实际情况调整。在部署前，请先检查：

- 已安装docker，如果没有请执行`wget -qO- https://get.docker.com/ | bash`安装docker。
- 一个域名并解析到运行Cloudreve的服务器，这里以`cloudreve.example.com`为例。

## 开始

### 创建Network

```bash
docker network create my-network
```

### 创建Nginx配置文件

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

### 启动Nginx服务

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

### 启动Aria2服务（如不需要离线下载功能该步骤略过）

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
    -v <PATH TO config>:/config \
    -v <PATH TO temp>:/downloads \
    p3terx/aria2-pro
```

说明

- PUID以及PGID的获取方式详见`获取PUID和PGID`。
- `<SECRET>`: Aria2 RPC密码（你可以去[这里](https://miniwebtool.com/zh-cn/random-string-generator/)生成随机字符串）。请记下该密码！在后续Cloudreve设置Aria2中会使用。
- `<PATH TO config>`: Aria2的配置文件夹，例如`/dockercnf/aria2/conf`。
- `<PATH TO temp>`: 临时下载文件夹，需要与Cloudreve的`/downloads`对应，例如`/dockercnf/aria2/temp`。
- 如果不需要外网访问Aria2可以将`#1`所在行删除。

### 启动Cloudreve

```bash
docker run -d \
  --name cloudreve \
  -e PUID=1000 \ # optional
  -e PGID=1000 \ # optional
  -e TZ="Asia/Shanghai" \ # optional
  --network my-network \
  --restart=unless-stopped \
  -v <PATH TO uploads>:/cloudreve/uploads \
  -v <PATH TO temp>:/downloads \ #1
  -v <PATH TO config>:/cloudreve/config \
  -v <PATH TO db>:/cloudreve/db \
  -v <PATH TO avatar>:/cloudreve/avatar \
  xavierniu/cloudreve
```

说明

- 首次启动后请执行`docker logs -f cloudreve`获取初始密码

- PUID以及PGID的获取方式详见`获取PUID和PGID`

- `<PATH TO uploads>`:上传目录, 例如`/sharedfolders`
- `<PATH TO temp>`: 临时下载文件夹，需要与Aria的`/downloads`对应，例如`/dockercnf/aria2/temp`（如不需要离线下载功能`#1`可以删除）
- `<PATH TO config>`: 配置文件夹，如`/dockercnf/cloudreve/config`
- `<PATH TO db>`: 数据库文件夹，如`/dockercnf/cloudreve/db`
- `<PATH TO avatar>`: 头像文件夹，如`/dockercnf/cloudreve/avatar`

### 配置Cloudreve连接Aria2服务器

- 以管理员身份登陆
- 点击"头像（右上角） > 管理面板"
- 点击"参数设置 > 离线下载"

  - RPC服务器地址: http://aria2:6800/
  - RPC Secret: 参见`启动Aria2服务`中的`<SECRET>`
  - 临时下载地址: /downloads
  - 其他选项按照默认值即可
- 测试连接并保存