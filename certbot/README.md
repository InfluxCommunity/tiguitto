# TIGUITTO CertBot (Standalone) Case

The __certbot__ Case generates necessary [Let's Encrypt](https://letsencrypt.org/) SSL Certificates via [`certbot` ACME client](https://certbot.eff.org/). The Certificates generated, will be used to secure __InfluxDB__, __Grafana__, __Mosquitto Broker__

## Environment Variables & Configuration Files

### Authentication

All necessary Environment Variables will be set in `certbot.env` file after executing:
1. `00-install-certbot.sh`
2. `01-generate-certs.sh`

### Telegraf

- Adapt the `topics`, `database` in the `telegraf/telegraf.conf` according to requirements
- Optionally add / remove the `[[processors.regex]]` and `[[processors.enum]]` logic from the `telegraf.conf` file

>  NOTE Since we will be using Certificates generated via `certbot`, we will be using Domain Name itself to connect to the MQTT broker and InfluxDB (variable `CB_DOMAIN` will be inserted in `certbot.env` after executing the scripts mentioned in __Authentication__)

### Mosquitto

If you wish to change the usernames/passwords for publishing and subscribing clients, edit the `mosquitto/config/passwd` file. The format for the file is as follows:

        username1:password1
        username2:password2

### SSL Certificates

> NOTE: you need to have a registered Domain Name in order for the `certbot` tool generate necessary certificates


## Steps to Bring the Stack Up

1. Create a network for your stack:

        docker create network iotstack

2. Encrypting the Passwords for Mosquitto Broker:

        # Assuming you are in the `certbot` directory
        docker run -it --rm $(pwd)/mosquitto/config:/mosquitto/config eclipse-mosquitto mosquitto_passwd -U /mosquitto/config/passwd
    
    If there is no response from the command, the passwords are encrypted. You can see the encrypted passwords using:

        cat mosquitto/config/passwd

3. Change Ownership for the Mosquitto Directories:

        sudo chown -R 1883:1883 mosquitto/log
        sudo chown -R 1883:1883 mosquitto/data
        sudo chown -R 1883:1883 mosquitto/config

### Certbot Installation + Certificate Generation

1. Execute the script `00-install-certbot.sh` (irrespective, if `certbot` is installed or not since the script will also setup HTTP Port (80) for `certbot`)

        sudo ./00-install-certbot.sh

    This is will install the `certbot` CLI + enable the HTTP Port via the firewall CLI

2. Execute the `01-generate-certs.sh` as follows:

        sudo ./01-generate-certs.sh <DOMAIN_NAME> <EMAIL_ADDRESS>
    
    This will generate all the necessary SSL Certificates for `DOMAIN_NAME` and place them in `/etc/letsencrypt/live/<DOMAIN_NAME>/` directory. It will also add the necessary Environment Variables to `certbot.env`

    Verify the Environment Variables:

        cat certbot.env

    A Typical `certbot.env` file looks like the following:

            # VARIABLES WILL BE GENERATED AFTER EXECUTING:
            #   01-generate-certs.sh SCRIPT
            DISTRO=Ubuntu
            CB_DOMAIN=myawesomedomain.com
            CB_EMAIL=test@myawesomedomain.com
            # InfluxDB Environment Variables
            INFLUXDB_HTTP_HTTPS_ENABLED=true
            INFLUXDB_HTTP_HTTPS_CERTIFICATE=/etc/letsencrypt/live/myawesomedomain.com/fullchain.pem
            INFLUXDB_HTTP_HTTPS_PRIVATE_KEY=/etc/letsencrypt/live/myawesomedomain.com/privkey.pem
            # Grafana Server Environment Variables
            GF_SERVER_PROTOCOL=https
            GF_SERVER_DOMAIN=myawesomedomain.com
            GF_SERVER_ROOT_URL=https://myawesomdomain.com
            GF_SERVER_CERT_FILE=/etc/letsencrypt/live/myawesomedomain.com/fullchain.pem
            GF_SERVER_CERT_KEY=/etc/letsencrypt/live/myawesomedomain.com/privkey.pem
            # Telegraf Environment Variables
            TG_MOSQUITTO_USERNAME=subclient
            TG_MOSQUITTO_PASSWORD=tiguitto

3. Bring the stack up:

    a. from the root directory:

            docker-compose -f certbot/docker-compose.certbot.yml up
    
    b. from the present `certbot` directory:

            docker-compose -f docker-compose.certbot.yml up

    Use the `-d` flag to detach from the stack logs.

4. You might need to change the ownership of the `/etc/letsencrypt/live/<DOMAIN_NAME>/` directory for Mosquitto Broker to access:

        sudo chown -R 1883:1883 /etc/letsencrypt/


## Availability

- Grafana should be available on `https://<DOMAIN_NAME>:3000/login`
- InfluxDB should be available on `https://<DOMAIN_NAME>:8086`
- Mosquitto Broker should be available on `ssl://<DOMAIN_NAME>:8883`