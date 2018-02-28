# Serverpilot Let's Encrypt
A bash script that installs and configures a Let’s Encrypt certificate for your websites being managed and/or hosted via ServerPilot.

## Usage
In order to get a certificate from Let’s Encrypt for your website's domain and enable HTTPS on your website, just follow these simple steps:
- Connect to your server with SSH as `root`
- Download and copy the script to `/usr/local/bin`  
  `cd /usr/local/bin && wget https://github.com/MatrixsoftIN/ServerpilotLetsEncrypt/blob/master/serverpilot-letsencrypt.sh`
- Run the following command to make it executable:  `sudo chmod +x serverpilot-letsencrypt.sh`
- Now run the script as `root` from anywhere and follow the screen instructions.

## Why does it need to run as `root`?
The script creates `<appname>.ssl.conf` file in `/etc/nginx-sp/vhosts.d/` and it requires `root` access

## Where are the log files?
All log files reside in `/var/log/letsencrypt`
