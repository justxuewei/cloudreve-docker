# Cloudreve Docker

![](https://img.shields.io/github/workflow/status/xavier-niu/cloudreve-docker/Publish%20Docker) ![](https://img.shields.io/badge/cloudreve-3.5.1-brightgreen) ![](https://img.shields.io/docker/image-size/xavierniu/cloudreve/latest) ![](https://img.shields.io/docker/pulls/xavierniu/cloudreve) ![](https://img.shields.io/badge/maintainer-xavierniu-lightgrey)

优势

- 基于最新的 [Cloudreve V3](https://github.com/cloudreve/Cloudreve)
- 长期维护
- 镜像体积小
- 纯净安装，无多余组件
- 支持多种架构（amd64, arm64, arm32/v7）
- 简易安装
- 内含详细的 Cloudreve+Nginx+Aria2 部署教程

## 获取 PUID 和 PGID

为什么要使用 PUID 和 PGID 参见 [Understanding PUID and PGID](https://docs.linuxserver.io/general/understanding-puid-and-pgid)。假设当前登陆用户为 `root`，则执行 `id root` 就会得到类似于下面的一段代码：

```
uid=1000(root) gid=1001(root)
```

则在运行命令中的 PUID 填入 `1000`，PGID填入 `1001`。

## 开始

目录

- `<PATH TO uploads>`:上传目录，如 `/sharedfolders`
- `<PATH TO config>`: 配置文件夹，如 `/dockercnf/cloudreve/config`
- `<PATH TO db>`: 数据库文件夹，如 `/dockercnf/cloudreve/db`
- `<PATH TO avatar>`: 头像文件夹，如 `/dockercnf/cloudreve/avatar`

创建配置文件夹

```bash
mkdir -p <PATH TO config>
```

创建配置文件 `vim <PATH TO config>/conf.ini `（*该配置文件针对 SQLite 数据库，如需使用 MySQL 等数据库，请参见 cloudreve 官方文档*）

```ini
# conf.ini
[Database]
DBFile = /cloudreve/db/cloudreve.db
```

启动 cloudreve 容器

```bash
docker run -d \
  --name cloudreve \
  -e PUID=1000 \ # optional
  -e PGID=1000 \ # optional
  -e TZ="Asia/Shanghai" \ # optional
  -p 5212:5212 \
  --restart=unless-stopped \
  -v <PATH TO uploads>:/cloudreve/uploads \
  -v <PATH TO config>:/cloudreve/config \
  -v <PATH TO db>:/cloudreve/db \
  -v <PATH TO avatar>:/cloudreve/avatar \
  xavierniu/cloudreve
```

说明

- 首次启动后请执行 `docker logs -f cloudreve` 获取初始密码；
- PUID 以及 PGID 的获取方式详见 `获取PUID和PGID`；
- `TZ` 设置时区，默认值为 `Asia/Shanghai`。

其他教程

- 如果你想使用 Nginx 作为反向代理服务器，或者使用 Aira2 作为离线下载服务，请参阅 [Cloudreve Docker - NAC](https://github.com/xavier-niu/cloudreve-docker/blob/master/README-NAC.md)；
- 如果你希望通过 docker-compose 的方式启动服务，请参阅 [Cloudreve Docker - Docker Compose](https://github.com/xavier-niu/cloudreve-docker/blob/master/README-DOCKER-COMPOSE.md)。
- 如果您想远程云端启动服务，请参阅 [Cloudreve Docker - TeamCode](https://github.com/xavier-niu/cloudreve-docker/blob/master/README-TEAMCODE.md) (每月免费使用时间有限制，超过则需支付费用)。

## 升级

首先请暂停并移除正在运行的容器并从 Docker Hub 拉取最新的镜像

```bash
docker stop cloudreve \
  && docker rm cloudreve \
  && docker pull xavierniu/cloudreve
```

重复上面的运行步骤再次启动容器即可。
