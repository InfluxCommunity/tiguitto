# TIGUITTO Prototype Case

The __Prototype__ Case quickly creates the TIG stack with __basic__ user authentication for all
components in the stack. This case provides the most basic level security, where username and passwords
are required for all the components.

## Environment Variables & Configuration Files

### Authentication

- Use the `prototype.env` file to change the default username and passwords for the stack components.

### Telegraf

- Adapt the `topics`, `database` in the `telegraf/telegraf.toml` according to your requirements
- Optionally add / remove the `[[processors.regex]]` logic from the `telegraf.conf` file

### Mosquitto

- If you wish to change the username/passwords for publishing and subscribing clients edit the `mosquitto/config/passwd` file.
    The format of the file is as follows:

        username1:password1
        username2:password2

## Steps to Bring the Prototype Stack Up

1. Create a network for your stack:

        docker network create iotstack

2. Encrypting the Passwords for Mosquitto Broker:

    ```bash
    cd prototype/
    docker run -it --rm -v $(pwd)/mosquitto/config:/mosquitto/config eclipse-mosquitto mosquitto_passwd -U /mosquitto/config/passwd
    ```

    If there is no response from the command the passwords are encrypted. You can see the encrypted passwords using:

        cat mosquitto/config/passwd

3. Bring the stack up:

        USER_ID="$(id -u)" GRP_ID="$(id -g)" docker-compose -f docker-compose.prototype.yml up
    
    add `-d` flag to detach the stack logs

## Component Availability behind Reverse-Proxy

|   Component  |  Credentials (username:password)  |                         Endpoint                         |
|:---------:|:-----------------:|:-----------------------------------------------------------------------------------------------------:|
| `traefik` | `admin:tiguitto`  | `curl -i -u admin:tiguitto http://localhost/dashboard/`<br> Browser: `http://<IP_ADDRESS>/dashboard/` |
| `grafana` | `admin:tiguitto`  | `curl -i -u admin:tiguitto http://localhost/grafana/api/health`<br> Browser: `http://<IP_ADDRESS>/grafana`       |
| `influxdb`| `tiguitto:tiguitto` | `curl -i -u tiguitto:tiguitto http://localhost/influxdb/ping` |
| `mosquitto` | `{sub,pub}client:tiguitto` | Use an MQTT Client here         |

## Component Logs
- For `telegraf`, `influxdb`, `grafana`, `mosquitto`, `traefik` stdout Logs:

        docker-compose -f docker-compose.prototype.yml logs -f telegraf
        # OR
        docker-compose -f docker-compose.prototype.yml logs -f influxdb
        # OR
        docker-compose -f docker-compose.prototype.yml logs -f grafana
        # OR
        docker-compose -f docker-compose.prototype.yml logs -f mosquitto
        # OR
        docker-compose -f docker-compose.prototype.yml logs -f traefik

## Component Ports

| Component   | Port  |
| ----------  | ----- |
| `influxdb`  | 8086 (internal)  |
| `telegraf`  | n/a (internal)  |
| `grafana`   | 3000 (internal) |
| `mosquitto` | 1883 (mqtt), 1884 (ws) (internal) |
| `traefik`   | 80, 1883, 1884 (external) |

## Component Level Security

### Mosquitto MQTT Broker

The `mosquitto/config/passwd` file has two users in it:


|   username  |  password  |                         role                         |
|:-----------:|:----------:|:----------------------------------------------------:|
| `pubclient` | `tiguitto` | Publishing Data to MQTT Broker. For IoT Sensor Nodes |
| `subclient` | `tiguitto` |       Subscribing to MQTT Broker. For Telegraf       |

The file needs to be encrypted in order for the Broker to accept it. Passwords in Mosquitto cannot be plain-text.

See __Step 2__ to encrypt your Mosquitto Broker Passwords.

### Telegraf

The configuration file (`telegraf.toml`) will use the following environment variables to write data into
InfluxDB

    INFLUXDB_USER=tiguitto
    INFLUXDB_USER_PASSWORD=tiguitto

The data will be written to a database called `edge` (`INFLUXDB_DB` in `prototype.env`)

Telegraf will use the following environment variables to subscribe to Mosquitto Broker

    TG_MOSQUITTO_USERNAME=subclient
    TG_MOSQUITTO_PASSWORD=tiguitto


### InfluxDB

- You can control the admin user and password via `INFLUXDB_ADMIN_USER` and `INFLUXDB_ADMIN_PASSWORD` variables in `prototype.env`
> `INFLUXDB_USER` can _have read and write privileges ONLY if_ `INFLUXDB_DB` is assigned. If there is no database assigned then the `INFLUXDB_USER` will not have any privileges.


### Grafana
Grafana container will use the following environment variables to set up an admin account

    GF_ADMIN_USERNAME=admin
    GF_ADMIN_PASSWORD=tiguitto


## Mosquitto Websocket Client using Paho-MQTT-Python

Code is as follows:

<details>

```python
import paho.mqtt.client as mqtt
import sys
HOST = '<YOUR_BROKER_IP_ADDRESS>'
PORT = 1884

CLIENT_ID='tiguitto-prototype-ws'

def on_connect(mqttc, obj, flags, rc):
    print("rc: "+str(rc))

def on_message(mqttc, obj, msg):
    print(msg.topic+" "+str(msg.qos)+" "+str(msg.payload))

def on_publish(mqttc, obj, mid):
    print("mid: "+str(mid))

def on_subscribe(mqttc, obj, mid, granted_qos):
    print("Subscribed: "+str(mid)+" "+str(granted_qos))

def on_log(mqttc, obj, level, string):
    print(string)

mqttc = mqtt.Client(CLIENT_ID, transport="websockets")


mqttc.on_message = on_message
mqttc.on_connect = on_connect
mqttc.on_publish = on_publish
mqttc.on_subscribe = on_subscribe
mqttc.on_log = on_log

mqttc.connect(HOST, PORT, 60)

mqttc.subscribe('IOT/#', 0)

try:
        mqttc.loop_forever()

except KeyboardInterrupt:
        mqttc.loop_stop()
        mqttc.disconnect()
        sys.exit()
```
</details>