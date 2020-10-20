# TIGUITTO Prototype Case

The __Prototype__ Case quickly creates the TIG stack with __basic__ user authentication for all
components in the stack. This case provides the most basic level security, where username and passwords
are required for all the components.

## Environment Variables & Configuration Files

### Authentication

- Use the `prototype.env` file to change the default username and passwords for the stack components.

### Telegraf

- Adapt the `topics`, `database` in the `telegraf/telegraf.conf` according to your requirements
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
    # Assuming you are in the `prototype` directory
    docker run -it --rm -v $(pwd)/mosquitto/config:/mosquitto/config eclipse-mosquitto mosquitto_passwd -U /mosquitto/config/passwd
    ```

    If there is no response from the command the passwords are encrypted. You can see the encrypted passwords using:

        cat mosquitto/config/passwd

3. Bring the stack up:

    a. from the root directory:

           USER_ID="$(id -u)" GRP_ID="$(id -g)" docker-compose -f prototype/docker-compose.prototype.yml up

    b. from the present `prototype` directory:

            USER_ID="$(id -u)" GRP_ID="$(id -g)" docker-compose -f docker-compose.prototype.yml up
    
    add `-d` flag to detach the stack logs

4. Create `admin` user for InfluxDB and give `telegraf` user all privileges. (from the shell, whereever you are):

    a. Create `admin` user with all privileges

            curl -XPOST 'http://localhost:8086/query' --data-urlencode "q=CREATE USER admin WITH PASSWORD 'tiguitto' WITH ALL PRIVILEGES"

    b. Give `telegraf` user all privileges

            curl -XPOST 'http://localhost:8086/query' \
                -u admin:tiguitto \
                --data-urlencode "q=CREATE USER telegraf WITH PASSWORD 'tiguitto' WITH ALL PRIVILEGES"

    This will allow Telegraf to insert data into the dedicated database

5. Grafana Should be available on http://localhost:3000/login with the following credentials:

        username: admin
        password: tiguitto
    
    You can use the InfluxDB credentials created in Step 4 to create an InfluxDB Datasource in Grafana

### Component Logs

<details>
- For `telegraf`, `influxdb`, `grafana`, `mosquitto` stdout Logs:

    a. from root directory:

        docker-compose -f prototype/docker-compose.prototype.yml logs -f telegraf
        # OR
        docker-compose -f prototype/docker-compose.prototype.yml logs -f influxdb
        # OR
        docker-compose -f prototype/docker-compose.prototype.yml logs -f grafana
        # OR
        docker-compose -f prototype/docker-compose.prototype.yml logs -f mosquitto

    b. from `prototype` (this) directory:

        docker-compose -f docker-compose.prototype.yml logs -f telegraf
        # OR
        docker-compose -f docker-compose.prototype.yml logs -f influxdb
        # OR
        docker-compose -f docker-compose.prototype.yml logs -f grafana
        # OR
        docker-compose -f docker-compose.prototype.yml logs -f mosquitto

</details>

---

## Ports for Components

| Component   | Port  |
| ----------  | ----- |
| `influxdb`  | 8086  |
| `telegraf`  | n/a   |
| `grafana`   | 3000  |
| `mosquitto` | 1883 (mqtt), 1884 (ws)  |

---

## Component Level Security

### Mosquitto MQTT Broker

<details>
The `mosquitto/config/passwd` file has two users in it:


|   username  |  password  |                         role                         |
|:-----------:|:----------:|:----------------------------------------------------:|
| `pubclient` | `tiguitto` | Publishing Data to MQTT Broker. For IoT Sensor Nodes |
| `subclient` | `tiguitto` |       Subscribing to MQTT Broker. For Telegraf       |

The file needs to be encrypted in order for the Broker to accept it. Passwords in Mosquitto cannot be plain-text.

See Step 1 for Reference
</details>

### Telegraf
<details>
The configuration file (`telegraf.conf`) will use the following environment variables to write data into
InfluxDB

    INFLUX_USERNAME=telegraf
    INFLUX_PASSWORD=tiguitto

The data will be written to a database called `edge` (change the name in the `telegraf.conf` accordingly)

Telegraf will use the following environment variables to subscribe to Mosquitto Broker

    TG_MOSQUITTO_USERNAME=subclient
    TG_MOSQUITTO_PASSWORD=tiguitto
</details>

### InfluxDB
<details>
> Since InfluxDB does not provide Environment Variables to setup an `admin` user, one needs to use `curl` to setup privileges

See Step 4 for Reference
</details>

### Grafana
<details>
Grafana container will use the following environment variables to set up an admin account

    GF_ADMIN_USERNAME=admin
    GF_ADMIN_PASSWORD=tiguitto

</details>


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