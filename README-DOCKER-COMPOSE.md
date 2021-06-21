# Cloudreve Docker - Docker Compose

## 使用Nginx作为服务器

在开始之前，请检查：

- 已安装docker，如果没有请执行`wget -qO- https://get.docker.com/ | bash`安装docker。
- 已安装docker compose，如果没有请参考[Install Docker Compose](https://docs.docker.com/compose/install/)。
- 一个域名并解析到运行Cloudreve的服务器，这里以`cloudreve.example.com`为例。
- 确保80和443端口没有被占用，如果您已经有服务器软件（如Nginx或Caddy），请考虑为原有服务器软件增加配置文件并删除docker compose配置文件中的caddy容器。

该docker-compose文件仅适用于linux/amd64架构，如果您正在使用arm请尝试修改部分参数。

### 预创建文件

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

### 下载环境文件以及Docker Compose文件

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
  - CLOUDREVE_CONF_PATH: Cloudreve配置文件夹路径
  - CLOUDREVE_DB_PATH: Cloudreve数据库文件夹路径

下载Docker Compose文件

```bash
wget -qO- https://raw.githubusercontent.com/xavier-niu/cloudreve-docker/master/docker-compose-amd64.yml > docker-compose.yml
```

### 启动Docker Compose

```bash
docker-compose up -d
```

说明

- Aria2-RPC会暴露于外网，访问端口`6800`，Secret为你对`ARIA2_RPC_SECRET`设置的随机字符串。

### 配置Cloudreve连接Aria2服务器

- 以管理员身份登陆
- 点击"头像（右上角） > 管理面板"
- 点击"参数设置 > 离线下载"

  - RPC服务器地址: `http://aria2:6800/`
  - RPC Secret: 你对`ARIA2_RPC_SECRET`设置的随机字符串
  - 临时下载地址: `/downloads`
  - 其他选项按照默认值即可
- 测试连接并保存

### 使用Traefik作为服务器

本方案由@expoli提供。Traefik是新一代的Web服务器，支持docker服务发现和自动申请HTTPS证书，只需修改相应的服务的label即可实现服务的反向代理，简化了配置。

相关配置请参阅[https://github.com/expoli/docker-compose-files](https://github.com/expoli/docker-compose-files)，Cloudreve使用**traefik + cloudreve + mysql + redis**实现。