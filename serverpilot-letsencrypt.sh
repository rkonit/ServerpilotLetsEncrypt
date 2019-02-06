#!/bin/bash
# Let's Encrypt SSL for ServerPilot app

# Settings
ubuntu=$(lsb_release -r -s)
confdir=/etc/nginx-sp/vhosts.d
acmeconfigdir=/etc/nginx-sp/letsencrypt.d
acmeconfigfile="$acmeconfigdir/letsencrypt-acme-challenge.conf"

# Make sure this script is run as root
if [ "$EUID" -ne 0 ]
then 
    echo ""
	echo "Please run this script as root."
	exit
fi

# Check for Ubuntu 16.04 Xenial Xerus
if [ $ubuntu != '16.04' ]
then
    echo ""
    echo "Your server must be Ubuntu 16.04 (64-bit)."
    exit
fi

# Check Let's Encrypt is installed
le=$(dpkg-query -W -f='${Status}' letsencrypt 2>/dev/null | grep -c "ok installed")
if [ $le == 0 ]
then
    echo "Let's Encrypt is not installed. Would you like to install it?"
    read -p "Y or N" -n 1 -r
    echo ""
    if [[ "$REPLY" =~ ^[Yy]$ ]]
    then
        sudo apt-get update
        sudo apt-get install letsencrypt -y
    fi 
fi

echo ""
echo ""
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo "  Let's Encrypt SSL for ServerPilot app"
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo ""
echo ""
echo "Please enter your app name:"
read appname
echo ""
echo "Please enter username for the app:"
read username
echo ""
echo "Please enter all the domain names and sub-domain names seprated by space"
read domains

# Assign domain names to array
APPDOMAINS=()
for domain in $domains; do
   APPDOMAINS+=("$domain")
done

# Assign domain list to array
APPDOMAINLIST=()
for domain in $domains; do
   APPDOMAINLIST+=("-d $domain")
done

# Generate Certificate
echo ""
echo "Generating SSL certificate for $appname"
echo ""
letsencrypt certonly --webroot -w /srv/users/$username/apps/$appname/public ${APPDOMAINLIST[@]}

# Check the ACME configuration file for Nginx
if [ ! -f "$acmeconfigfile" ] 
then
    echo ""
    echo "Creating configuration file $acmeconfigfile for ACME"
    
    mkdir $acmeconfigdir
    touch $acmeconfigfile
    
    echo "location ~ /\.well-known\/acme-challenge {" | sudo tee $acmeconfigfile
    echo "    allow all;" | sudo tee -a $acmeconfigfile
    echo "}" | sudo tee -a $acmeconfigfile
    echo "" | sudo tee -a $acmeconfigfile
    echo "location = /.well-known/acme-challenge/ {" | sudo tee -a $acmeconfigfile
    echo "    return 404;" | sudo tee -a $acmeconfigfile
    echo "}" | sudo tee -a $acmeconfigfile
fi

# Generate nginx configuration file
configfile=$confdir/$appname.ssl.conf
echo ""
echo "Creating configuration file for $appname in the $confdir"
sudo touch $configfile
echo "server {" | sudo tee $configfile 
echo "   listen 443 ssl http2;" | sudo tee -a $configfile 
echo "   listen [::]:443 ssl http2;" | sudo tee -a $configfile 
echo "   server_name " | sudo tee -a $configfile 
   for domain in $domains; do
      echo -n $domain" " | sudo tee -a $configfile
   done
echo ";" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "   # letsencrypt certificates" | sudo tee -a $configfile 
echo "   ssl_certificate      /etc/letsencrypt/live/${APPDOMAINS[0]}/fullchain.pem;" | sudo tee -a $configfile 
echo "   ssl_certificate_key  /etc/letsencrypt/live/${APPDOMAINS[0]}/privkey.pem;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "   # SSL Optimization" | sudo tee -a $configfile 
echo "   ssl_session_timeout 1d;" | sudo tee -a $configfile 
echo "   ssl_session_cache shared:SSL:20m;" | sudo tee -a $configfile 
echo "   ssl_session_tickets off;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "   # modern configuration" | sudo tee -a $configfile 
echo "   ssl_protocols TLSv1 TLSv1.1 TLSv1.2;" | sudo tee -a $configfile 
echo "   ssl_prefer_server_ciphers on;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "   ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "   # OCSP stapling" | sudo tee -a $configfile 
echo "   ssl_stapling on;" | sudo tee -a $configfile 
echo "   ssl_stapling_verify on;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "   # verify chain of trust of OCSP response" | sudo tee -a $configfile 
echo "   ssl_trusted_certificate /etc/letsencrypt/live/${APPDOMAINS[0]}/chain.pem;" | sudo tee -a $configfile
echo "" | sudo tee -a $configfile 
echo "   # OWASP Secure Headers Project" | sudo tee -a $configfile 
echo "   add_header Strict-Transport-Security 'max-age=31536000; includeSubDomains; preload';" | sudo tee -a $configfile
echo "   add_header X-Frame-Options SAMEORIGIN;" | sudo tee -a $configfile
echo "   add_header X-Content-Type-Options nosniff;" | sudo tee -a $configfile
echo "   add_header X-XSS-Protection '1; mode=block';" | sudo tee -a $configfile
echo "" | sudo tee -a $configfile 
echo "   # root directory and logfiles" | sudo tee -a $configfile 
echo "   root /srv/users/$username/apps/$appname/public;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "   access_log /srv/users/$username/log/$appname/${appname}_nginx.access.log main;" | sudo tee -a $configfile 
echo "   error_log /srv/users/$username/log/$appname/${appname}_nginx.error.log;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "   # proxyset" | sudo tee -a $configfile 
echo "   proxy_set_header Host \$host;" | sudo tee -a $configfile 
echo "   proxy_set_header X-Real-IP \$remote_addr;" | sudo tee -a $configfile 
echo "   proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;" | sudo tee -a $configfile 
echo "   proxy_set_header X-Forwarded-SSL on;" | sudo tee -a $configfile 
echo "   proxy_set_header X-Forwarded-Proto \$scheme;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "   # includes" | sudo tee -a $configfile 
echo "   include /etc/nginx-sp/vhosts.d/$appname.d/*.conf;" | sudo tee -a $configfile 
echo "   include $acmeconfigdir/*.conf;" | sudo tee -a $configfile 
echo "}" | sudo tee -a $configfile 

# Check Let's Encrypt auto-renewal enabled
job=$(crontab -l 2>/dev/null | grep -c "letsencrypt renew")
if [ $job == 0 ] 
then
    echo "Would you like to add a cron job to enable auto-renwal?"
    read -p "Y or N" -n 1 -r
    echo ""
    if [[ "$REPLY" =~ ^[Yy]$ ]]
    then
        # Append new schedule to crontab
        crontab -l 2>/dev/null | { cat; echo "0 */12 * * * letsencrypt renew && service nginx-sp reload"; } | crontab -
    fi  
fi

# Wrapping it up
echo ""
echo "Opening HTTPS Port and  Restarting nginx..."
sudo ufw allow https
sudo service nginx-sp restart

echo ""
echo "Your Let's Encrypt SSL certificate has been installed. Please update your .htaccess to force HTTPS on your app"
echo ""
echo "# BEGIN HTTPS Redirection"
echo "<IfModule mod_rewrite.c>"
echo "RewriteEngine On"
echo "RewriteCond %{SERVER_PORT} !^443$"
echo "RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]"
echo "</IfModule>"
echo "# END HTTPS Redirection"

echo ""
echo "Cheers!"
echo ""
