#!/bin/bash
#============================================================================
#       FILE: generate-certs.sh
#       USAGE: ./generate-certs.sh
#   DESCRIPTION: Script to generate self-signed certificates for:
#                   1. Certificate Authority (CA)
#                   2. InfluxDB
#                   3. Mosquitto MQTT Broker            
#                
#============================================================================

ROOT_UID=0
E_NOTROOT=87
CERTSDIR="certs"

# Subjects for OpenSSL
SUBJECT_CA="/OU=CA"
SUBJECT_MQTT_SERVER="/OU=MQTT_SERVER"
SUBJECT_MQTT_CLIENT="/OU=MQTT_CLIENT"
SUBJECT_INFLUXDB="/OU=INFLUXDB_SERVER"

#===  FUNCTION  ================================================================
#          NAME:  generate_CA
#   DESCRIPTION:  Generate the CA key and CA Cert
#    PARAMETERS:  none
#       RETURNS:  none
#===============================================================================
function generate_CA() {
    echo "Generating CA Key and Certificate"
    echo "Please fill out the details according to needs"
    openssl req -x509 -nodes -sha256 -newkey rsa:2048 -subj "$SUBJECT_CA" -days 3650 -keyout ca.key -out ca.crt
}

#===  FUNCTION  ================================================================
#          NAME:  generate_mqtt_server_cert
#   DESCRIPTION:  Generate Certificate for MQTT Broker
#    PARAMETERS:  none
#       RETURNS:  none
#===============================================================================
function generate_mqtt_server_cert () {

    echo "Generating Server Certificate and Key for MQTT Broker"
    echo "Please fill out the details according to needs"
    openssl req -nodes -sha256 -new -subj "$SUBJECT_MQTT_SERVER" -keyout mqtt-server.key -out mqtt-server.csr
    
    echo "Sending Request to CA...."
    openssl x509 -req -sha256 -in mqtt-server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out mqtt-server.crt -days 3650
}

#===  FUNCTION  ================================================================
#          NAME:  generate_mqtt_client_cert
#   DESCRIPTION:  Generate Certificate and key for MQTT Clients for Publishing Data
#    PARAMETERS:  none
#       RETURNS:  none
#===============================================================================
function generate_mqtt_client_cert () {

    echo "Generating Server Certificate and Key for MQTT Client to Publish data to Broker. Used on IOT Nodes"
    echo "Please fill out the details according to needs"
    openssl req -new -nodes -sha256 -subj "$SUBJECT_MQTT_CLIENT" -out mqtt-client.csr -keyout mqtt-client.key 

    echo "Sending Request to CA...."
    openssl x509 -req -sha256 -in mqtt-client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out mqtt-client.crt -days 3650
}

#===  FUNCTION  ================================================================
#          NAME:  generate_influxdb_server_cert
#   DESCRIPTION:  Generate Certificate for InfluxDB
#    PARAMETERS:  none
#       RETURNS:  none
#===============================================================================
function generate_influxdb_server_cert () {

    echo "Generating Server Certificate and Key for InfluxDB"
    echo "Please fill out the details according to needs"
    openssl req -nodes -sha256 -new -subj "$SUBJECT_INFLUXDB" -keyout influxdb-server.key -out influxdb-server.csr

    echo "Sending Request to CA...."
    openssl x509 -req -sha256 -in influxdb-server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out influxdb-server.crt -days 3650
}


#-------------------------------------------------------------------------------
#   Check if Script is running with Root Privileges
#-------------------------------------------------------------------------------


if [ "$UID" -ne "$ROOT_UID" ]; then
	echo -e "Must be Root to run this script\n"
	exit $E_NOTROOT
fi

cd $CERTSDIR
generate_CA
generate_mqtt_server_cert
generate_influxdb_server_cert
generate_mqtt_client_cert
