# TIGUITTO Self-Signed Case

The __Self-Signed__ Case generates necessary Certificates in order to provide __TLS__ Security for components. This case
adds upon the __Prototype__ Case by adding more security in addition to basic authentication.

## Environment Variables & Configuration Files

__Authentication__:

- Use the `selfsigned.env` file to change the default username and passwords for the stack components.
- Additionally, InfluxDB will be up with HTTPS

__Telegraf__:

- Adapt the `topics`, `database` in the `telegraf/telegraf.conf` according to requirements
- Optionally add / remove the `[[processors.regex]]` logic from the `telegraf.conf` file
- Additionally, `insecure_skip_verify` is set to true since we use Self-Signed Certificates

__Mosquitto__:

- if you wish to change the usernames/passwords for publishing and subscribing clients edit the `mosquitto/config/passwd` file. The
format of the file is as follows:

    username1:password1
    username2:password2

__Self-Signed Certificates__:

- The bash script `generate-certs.sh` uses `openssl` to generate:
    1. __Certificate Authority (CA)__ key and certificate
    2. keys and certificates for InfluxDB, Mosquitto

    This requires subjects which has some hard-coded information in the script. Feel Free to change the `SUBJECT_*` variables' geographical and organizational values.

- > __NOTE__: _DO NOT CHANGE_ the `CN` value is you decide to change `SUBJECT_*` variables

## Steps to Bring the Protocol Stack Up

1. Create a network for your stack:

        docker create network iotstack

2. Encrypting the Passwords for Mosquitto Broker:

        # Assuming you are in the `selfsigned` directory
        docker run -it --rm $(pwd)/mosquitto/config:/mosquitto/config eclipse-mosquitto mosquitto_passwd -U /mosquitto/config/passwd

    If there is no response from the command, the passwords are encrypted. You can see the encrypted passwords using:

        cat mosquitto/config/passwd

3. Change the Ownership for the Mosquitto Directories:

        sudo chown -R 1883:1883 mosquitto/log
        sudo chown -R 1883:1883 mosquitto/data
        sudo chown -R 1883:1883 mosquitto/config

4. Generate Self-Signed Certificates using the script:

        ./generate-certs.sh
    
    a. During initial Creation for __CA__, you will be asked to enter __PEM Passphrase__. You can keep it whatever you want, but you will need it everytime you create a new certificate. For simplicity use `tiguitto`

    b. This should create the following certificates and keys in the `certs` folder:

            certs/
            ├── ca.crt
            ├── ca.key
            ├── ca.srl
            ├── influxdb
            │   ├── ca.crt
            │   ├── influx-server.crt
            │   ├── influx-server.csr
            │   └── influx-server.key
            └── mqtt
                ├── ca.crt
                ├── mqtt-server.crt
                ├── mqtt-server.csr
                └── mqtt-server.key

        NOTE: We copy the `ca.crt` in each component directory in order to keep the mount volumes in the compose file simple.

5. Change the Ownership for the certificate directories according to the components:

        sudo chown -R 1883:1883 certs/mqtt/
        sudo chown -R influxdb:influxdb certs/influxdb/

6. Bring the Stack up:

    a. from the root directory:

            docker-compose -f prototype/docker-compose.prototype.yml up

    b. from the present `prototype` directory:

            docker-compose -f docker-compose.prototype.yml up
    
    This should bring the services up for TIGUITTO. add `-d` flag to detach the stack logs

7. Create `admin` user for InfluxDB and give `telegraf` user all privileges. (from the shell, whereever you are):

    a. Create `admin` user with all privileges

            curl -XPOST 'https://localhost:8086/query' --data-urlencode "q=CREATE USER admin WITH PASSWORD 'tiguitto' WITH ALL PRIVILEGES" --insecure

    b. Give `telegraf` user all privileges

            curl -XPOST 'https://localhost:8086/query' \
                -u admin:tiguitto \
                --data-urlencode "q=CREATE USER telegraf WITH PASSWORD 'tiguitto' WITH ALL PRIVILEGES" --insecure

    This will allow Telegraf to insert data into the dedicated database.
    
    NOTE: use the `--insecure` parameter when querying self-signed certificate server

## Publishing with MQTT Clients

You will require all devices or Apps that will publish data to the TIGUITTO Broker to have the `ca.crt` on them along with the user `pubclient`. The certificate will enable SSL/TLS and the authentication will only allow dedicated devices to publish data to the Broker.

### Typical MQTT Client Configuration

| Conf | Value        |
|------|--------------|
| Host | <IP_Address> |
| Port | 8883         |
| User | `pubclient`  |
| TLS  | `v1.2`       |
| Pass | `tiguitto`   |
| cert | `ca.crt`     |


## Grafana Configuration
Change the values accordingly in the Data Sources Section of Grafana.

[Source](https://devconnected.com/how-to-setup-telegraf-influxdb-and-grafana-on-linux/)

### Data Sources Configuration for InfluxDB
    
|  Field   |       Value                |
|----------|----------------------------| 
| HTTP_URL |    `https://influxdb:8086` |
| Auth_Basic_auth | `true`              |
| Auth_Skip_TLS_Verify | `true`         |
| Auth_With_Credentials | `true`        |
| Basic Auth Details | User: `admin`, Password: `tiguitto`|
| InfluxDB Details_Database | Database: `edge`  |
| InfluxDB Details_User | `admin` |
| InfluxDB Details_Password | `tiguitto` |
