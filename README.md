# Cloudreve Docker

![](https://img.shields.io/github/workflow/status/xavier-niu/cloudreve-docker/Publish%20Docker) ![](https://img.shields.io/badge/cloudreve-3.3.1-brightgreen) ![](https://img.shields.io/docker/image-size/xavierniu/cloudreve/latest) ![](https://img.shields.io/docker/pulls/xavierniu/cloudreve) ![](https://img.shields.io/badge/maintainer-xavierniu-lightgrey)

优势

- 基于最新的[Cloudreve V3](https://github.com/cloudreve/Cloudreve)
- 长期维护
- 镜像体积小
- 纯净安装，无多余组件
- 支持多种架构(amd64, arm64, arm32/v7)
- 简易安装
- 内含详细的Cloudreve+Nginx+Aria2部署教程

## 更新日志

May 27, 2021: 取消了预创建conf.ini和cloudreve.db过程。原则上数据库的迁移工作是无感的，但是强烈建议**v3.3.1及以下版本**更新到最新版本之前，先备份旧版本的cloudreve.db和conf.ini文件（可以通过`docker logs -f cloudreve`查看当前的版本）。更新完成后，请将cloudreve.db文件复制到`<PATH TO db>`，向conf.ini文件追加数据库路径（如下所示）后复制到`<PATH TO config>`。

```bash
# conf.ini
# 向下追加
[Database]
DBFile = /cloudreve/db/cloudreve.db
```

## 获取PUID和PGID

为什么要使用PUID和PGID参见[Understanding PUID and PGID](https://docs.linuxserver.io/general/understanding-puid-and-pgid)。假设当前登陆用户为`root`，则执行`id root`就会得到类似于下面的一段代码：

```
uid=1000(root) gid=1001(root)
```

则在运行命令中的PUID填入`1000`，PGID填入`1001`。

## 开始

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

- 首次启动后请执行`docker logs -f cloudreve`获取初始密码
- PUID以及PGID的获取方式详见`获取PUID和PGID`
- `TZ`设置时区，默认值为`Asia/Shanghai`
- `<PATH TO uploads>`:上传目录, 例如`/sharedfolders`
- `<PATH TO config>`: 配置文件夹，如`/dockercnf/cloudreve/config`
- `<PATH TO db>`: 数据库文件夹，如`/dockercnf/cloudreve/db`
- `<PATH TO avatar>`: 头像文件夹，如`/dockercnf/cloudreve/avatar`

如果你想使用Nginx作为反向代理服务器，或者使用Aira2作为离线下载服务，请参阅[Cloudreve Docker - NAC](https://github.com/xavier-niu/cloudreve-docker/blob/master/README-NAC.md)。如果你希望通过docker-compose的方式启动服务，请参阅[Cloudreve Docker - Docker Compose](https://github.com/xavier-niu/cloudreve-docker/blob/master/README-DOCKER-COMPOSE.md)。

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
