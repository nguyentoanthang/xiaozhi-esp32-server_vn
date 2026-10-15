# How to Build Docker Images Locally

This project now uses `github`'s `automatic docker image build` feature. If you pull the images released by the project, you have no need to build images yourself, so you can ignore this document.

If you have modified the source code and want to deploy and run it with `docker`, follow the steps below:

## 1. Prepare the environment

Install docker:
```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## 2. Build the images

After you have modified the code and need to build new images, follow these steps:

Get your `your username` and `new version number` ready.
- The `your username` is the username you registered on `docker hub`, for example `xiaozhi`. Of course, if you do not need to push to `docker hub`, you can define it freely.
- The `new version number` is the version of the image you build, for example `1.2.3`. You can customize it or use a date format (for example `20260609`). The main purpose is to distinguish it from the version currently running and to help you remember later when you built it. Do not use the same version number as the one currently running on your machine.

Go to the root directory of the `xiaozhi-esp32-server` project and build the server and web images:

```bash
cd <project root directory>

# Build the server image
docker build -f Dockerfile-server -t your-username/xiaozhi-esp32-server:new-version .

# Build the web image
docker build -f Dockerfile-web -t your-username/xiaozhi-esp32-server-web:new-version .

```

## 3. Modify the docker-compose configuration

```bash
cd main/xiaozhi-server
```

Edit the `docker-compose_all.yml` file and replace the image versions with the ones you just built:

```yaml
services:
  xiaozhi-esp32-server:
    image: your-username/xiaozhi-esp32-server:new-version   # Change to your image address
    ...

  xiaozhi-esp32-server-web:
    image: your-username/xiaozhi-esp32-server-web:new-version   # Change to your image address
    ...
```

## 4. Restart the services

```bash
# Stop the old containers
docker compose -f docker-compose_all.yml down

# Start the new containers
docker compose -f docker-compose_all.yml up -d
```

## 5. Verify

Check the logs to confirm that the services started normally:

```bash
# View the server logs
docker logs -f -n 50 xiaozhi-esp32-server

# View the web logs
docker logs -f -n 50 xiaozhi-esp32-server-web
```
