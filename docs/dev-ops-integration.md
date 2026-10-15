# Auto-Upgrade Method for Full-Module Source Deployment

This tutorial is for enthusiasts running a full-module source deployment. It shows how to use automated commands to pull the source code, build it, and start the services on their ports automatically, so that you can upgrade the system as efficiently as possible.

This project's test platform, `https://2662r3426b.vicp.fun`, has used this method since it opened, with good results.

You can also refer to the video tutorial published by the Bilibili creator `Bile labs`: [Step-by-step tutorial on auto-updating the open-source Xiaozhi server xiaozhi-server and configuring the latest MCP endpoint](https://www.bilibili.com/video/BV15H37zHE7Q)

# Prerequisites
- Your computer/server runs Linux
- You have already gotten the whole process working
- You like to keep up with the latest features but find manual deployment each time a bit troublesome, and hope for an automatic update method

The second condition must be met, because some of the files and environments covered in this tutorial (the JDK, Node.js environment, Conda environment, etc.) only exist once you have gotten the whole process working. If you have not, you may not understand what I mean when I mention a particular file.

# What This Tutorial Achieves
- Solves the problem of being unable to pull the latest project source code from within China
- Automatically pulls the code and builds the frontend files
- Automatically pulls the code and builds the Java files, kills the process on port 8002, and restarts port 8002
- Automatically pulls the Python code, kills the process on port 8000, and restarts port 8000

# Step 1: Choose Your Project Directory

For example, my planned project directory is the one below. It is a newly created empty directory; if you want to avoid mistakes, you can use the same one
```
/home/system/xiaozhi
```

# Step 2: Clone This Project
Now run the first command to pull the source code. This command works for servers and computers on mainland China networks, with no VPN needed

```
cd /home/system/xiaozhi
git clone https://ghproxy.net/https://github.com/xinnan-tech/xiaozhi-esp32-server.git
```

After it finishes, your project directory will contain a new folder `xiaozhi-esp32-server`. This is the project source code

# Step 3: Copy the Base Files

If you have already gotten the whole process working, you will be familiar with these two files: the funasr model file `xiaozhi-server/models/SenseVoiceSmall/model.pt` and your private configuration file `xiaozhi-server/data/.config.yaml`.

Now you need to copy the `model.pt` file to the new directory. You can do it like this
```
# Create the required directories
mkdir -p /home/system/xiaozhi/xiaozhi-esp32-server/main/xiaozhi-server/data/

cp <full path of your original .config.yaml> /home/system/xiaozhi/xiaozhi-esp32-server/main/xiaozhi-server/data/.config.yaml
cp <full path of your original model.pt> /home/system/xiaozhi/xiaozhi-esp32-server/main/xiaozhi-server/models/SenseVoiceSmall/model.pt
```

# Step 4: Create Three Auto-Build Scripts

## 4.1 Auto-build the manager-web module
In the `/home/system/xiaozhi/` directory, create a file named `update_8001.sh` with the following content

```
cd /home/system/xiaozhi/xiaozhi-esp32-server
git fetch --all
git reset --hard
git pull origin main


cd /home/system/xiaozhi/xiaozhi-esp32-server/main/manager-web
npm install
npm run build
rm -rf /home/system/xiaozhi/manager-web
mv /home/system/xiaozhi/xiaozhi-esp32-server/main/manager-web/dist /home/system/xiaozhi/manager-web
```

After saving, run the permission command
```
chmod 777 update_8001.sh
```
When it finishes, continue

## 4.2 Auto-build and run the manager-api module
In the `/home/system/xiaozhi/` directory, create a file named `update_8002.sh` with the following content

```
cd /home/system/xiaozhi/xiaozhi-esp32-server
git pull origin main


cd /home/system/xiaozhi/xiaozhi-esp32-server/main/manager-api
rm -rf target
mvn clean package -Dmaven.test.skip=true
cd /home/system/xiaozhi/

# Find the process ID using port 8002
PID=$(sudo netstat -tulnp | grep 8002 | awk '{print $7}' | cut -d'/' -f1)

rm -rf /home/system/xiaozhi/xiaozhi-esp32-api.jar
mv /home/system/xiaozhi/xiaozhi-esp32-server/main/manager-api/target/xiaozhi-esp32-api.jar /home/system/xiaozhi/xiaozhi-esp32-api.jar

# Check whether a process ID was found
if [ -z "$PID" ]; then
  echo "No process found using port 8002"
else
  echo "Found a process using port 8002, process ID: $PID"
  # Kill the process
  kill -9 $PID
  kill -9 $PID
  echo "Killed process $PID"
fi

nohup java -jar xiaozhi-esp32-api.jar --spring.profiles.active=dev &

tail -f nohup.out
```

After saving, run the permission command
```
chmod 777 update_8002.sh
```
When it finishes, continue

## 4.3 Auto-build and run the Python project
In the `/home/system/xiaozhi/` directory, create a file named `update_8000.sh` with the following content

```
cd /home/system/xiaozhi/xiaozhi-esp32-server
git pull origin main

# Find the process ID using port 8000
PID=$(sudo netstat -tulnp | grep 8000 | awk '{print $7}' | cut -d'/' -f1)

# Check whether a process ID was found
if [ -z "$PID" ]; then
  echo "No process found using port 8000"
else
  echo "Found a process using port 8000, process ID: $PID"
  # Kill the process
  kill -9 $PID
  kill -9 $PID
  echo "Killed process $PID"
fi
cd main/xiaozhi-server
# Initialize the conda environment
source ~/.bashrc
conda activate xiaozhi-esp32-server
pip install -r requirements.txt
nohup python app.py >/dev/null &
tail -f /home/system/xiaozhi/xiaozhi-esp32-server/main/xiaozhi-server/tmp/server.log
```

After saving, run the permission command
```
chmod 777 update_8000.sh
```
When it finishes, continue

# Routine Updates

Once all the scripts above are created, for routine updates we only need to run the following commands in order to update and start automatically

```
cd /home/system/xiaozhi
# Update and start the Java program
./update_8001.sh
# Update the web program
./update_8002.sh
# Update and start the Python program
./update_8000.sh


# To view the Java logs later, run the following command
tail -f nohup.out
# To view the Python logs later, run the following command
tail -f /home/system/xiaozhi/xiaozhi-esp32-server/main/xiaozhi-server/tmp/server.log
```

# Notes
The test platform `https://2662r3426b.vicp.fun` uses nginx as a reverse proxy. For the detailed nginx.conf configuration, [see here](https://github.com/xinnan-tech/xiaozhi-esp32-server/issues/791)

## FAQ

### 1. Why can't I see port 8001?
Answer: Port 8001 is used in the development environment to run the frontend. If you deploy on a server, it is not recommended to start the frontend on port 8001 with `npm run serve`. Instead, build it into HTML files as in this tutorial and use nginx to manage access.

### 2. Do I need to run SQL statements manually for each update?
Answer: No. The project uses **Liquibase** to manage database versions and automatically runs new SQL scripts.