#!/bin/bash
#============================================================================
#       FILE: 01-generate-certs.sh
#       USAGE: sudo ./01-generate-certs.sh <DOMAINNAME> <EMAIL>
#   DESCRIPTION: generating SSL certificates for given Domain + Email via certbot
#============================================================================

ROOT_UID=0
E_NOTROOT=87

MOSQUITTO_CONF=$(pwd)/mosquitto/config/mosquitto.conf
ENVFILE="certbot.env"

if [ "$UID" -ne "$ROOT_UID" ]; then
	echo -e "Must be Root to run this script\n"
	exit $E_NOTROOT
fi

if [ $# -lt 2 ]; then
	echo -e "\n USAGE: `basename $0` <DOMAIN_NAME> <EMAIL>"
	exit 1
else
	DOMAIN=$1
	EMAIL=$2
    echo -e "## CERTBOT Environment Variables\n"
	echo -e "CB_DOMAIN=$DOMAIN" >> $ENVFILE
	echo -e "CB_EMAIL=$EMAIL" >> $ENVFILE
fi

echo "#-------------------------------------------------------------------------------"
echo "#   Checking if certbot exists on machine"
echo "#-------------------------------------------------------------------------------"

if ! command -v certbot &> /dev/null; then
	echo -e "certbot not installed on machine\n"
    echo -e "Please execute 00-install-certbot.sh script first"
	exit 1
else
	echo -e "certbot already exists on machine\n"
fi

echo "#-------------------------------------------------------------------------------"
echo "#   Generating SSL Certificates for the Domain using certbot"
echo "#-------------------------------------------------------------------------------"

certbot certonly \
	--standalone \
	--preferred-challenges http \
	--agree-tos \
	-m $EMAIL \
	-d $DOMAIN

cert_return=$?

if [ $cert_return -ne 0 ]; then
	echo -e "certbot threw errors while generating certificates\n"
	exit $cert_return
fi


#-------------------------------------------------------------------------------
#   Check if Directory for generated certificates exists and files exist within it
#-------------------------------------------------------------------------------

CERTDIR=/etc/letsencrypt/live/$DOMAIN

echo -e "Certificate Directory: $CERTDIR\n"

if [ -d $CERTDIR ]; then
	echo -e "Domain directory in letsencrypt directory exists\n"
	echo -e "Checking for certificates in the directory\n"

	if [[ -f $CERTDIR/fullchain.pem ]] && [[ -f $CERTDIR/privkey.pem ]]; then
		echo -e "Necessary certificates for SSL/HTTPS exist\n"
	else
		echo -e "No Certificates exist. Please check certbot logs\n"
		exit 3
	fi
else
	echo -e "No domain directory exists. Please check certbot logs\n"
	exit 3
fi


# Setup Variables for Certificates for Insertion into configuration file + Env file
CAFILE=$CERTDIR/chain.pem
CERTFILE=$CERTDIR/fullchain.pem
KEYFILE=$CERTDIR/privkey.pem

#-------------------------------------------------------------------------------
#   Adding Relevant files and Paths to Environment Variable Files
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#   INFLUXDB ENVIRONMENT VARIABLES FOR HTTPS
#-------------------------------------------------------------------------------
echo -e "# InfluxDB Environment Variables" >> $ENVFILE
echo -e "INFLUXDB_HTTP_HTTPS_ENABLED=true" >> $ENVFILE
echo -e "INFLUXDB_HTTP_HTTPS_CERTIFICATE=$CERTFILE" >> $ENVFILE
echo -e "INFLUXDB_HTTP_HTTPS_PRIVATE_KEY=$KEYFILE" >> $ENVFILE


#-------------------------------------------------------------------------------
#   GRAFANA ENVIRONMENT VARIABLES FOR HTTPS
#-------------------------------------------------------------------------------
echo -e "# Grafana Server Environment Variables" >> $ENVFILE
echo -e "GF_SECURITY_ADMIN_USER=admin" >> $ENVFILE
echo -e "GF_SECURITY_ADMIN_PASSWORD=tiguitto" >> $ENVFILE
echo -e "GF_SERVER_PROTOCOL=https" >> $ENVFILE
echo -e "GF_SERVER_DOMAIN=$DOMAIN" >> $ENVFILE
echo -e "GF_SERVER_ROOT_URL=https://$DOMAIN" >> $ENVFILE
echo -e "GF_SERVER_CERT_FILE=$CERTFILE" >> $ENVFILE
echo -e "GF_SERVER_CERT_KEY=$KEYFILE" >> $ENVFILE

#-------------------------------------------------------------------------------
#   TELEGRAF ENVIRONMENT VARIABLES
#-------------------------------------------------------------------------------
echo -e "# Telegraf Environment Variables" >> $ENVFILE
echo -e "TG_MOSQUITTO_USERNAME=subclient" >> $ENVFILE
echo -e "TG_MOSQUITTO_PASSWORD=tiguitto" >> $ENVFILE

#-------------------------------------------------------------------------------
#   Add TLS Certificate Paths to Mosquitto Configuration File
#-------------------------------------------------------------------------------

echo -e "Adapting the Mosquitto Configuration file\n"

sed -i "s|##CAFILE|$CAFILE|g" $MOSQUITTO_CONF
sed -i "s|##CERTFILE|$CERTFILE|g" $MOSQUITTO_CONF
sed -i "s|##KEYFILE|$KEYFILE|g" $MOSQUITTO_CONF

exit 0