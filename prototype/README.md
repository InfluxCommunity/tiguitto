# TIGUITTO Prototype Case

The __Prototype__ Case quickly creates the TIG stack with __basic__ user authentication for all
components in the stack. This case provides the most basic level security, where username and passwords
are required for all the components.

## Environment Variables & Configuration Files

__Authentication__:

- Use the `prototype.env` file to change the default username and passwords for the stack components.

__Telegraf__:

- Adapt the `topics`, `database` in the `telegraf/telegraf.conf` according to your requirements
- Optionally add / remove the `[[processors.regex]]` logic from the `telegraf.conf` file

__Mosquitto__:

- If you wish to change the username/passwords for publishing and subscribing clients edit the `mosquitto/config/passwd` file.
    The format of the file is as follows:

        username1:password1
        username2:password2

## Steps to Bring the Prototype Stack Up

1. Create a network for your stack:

    docker create network iotstack

2. Encrypting the Passwords for Mosquitto Broker:
    ```bash
    # Assuming you are in the `prototype` directory
    docker run -it --rm -v $(pwd)/mosquitto/config:/mosquitto/config eclipse-mosquitto mosquitto_passwd -U /mosquitto/config/passwd
    ```

    If there is no response from the command the passwords are encrypted. You can see the encrypted passwords using:

        cat mosquitto/config/passwd

3. Change the Ownership for the Mosquitto Directories:

        sudo chown -R 1883:1883 mosquitto/log
        sudo chown -R 1883:1883 mosquitto/data
        sudo chown -R 1883:1883 mosquitto/config

    This seems to be a problem with `eclipse-mosquitto` docker image (see [Mosquitto Issue #1078](https://github.com/eclipse/mosquitto/issues/1078)). Although `user: "1883"` is defined in the Compose file, the logs are not written and hence the Broker exits with failure.

4. Bring the stack up:

    a. from the root directory:

            docker-compose -f prototype/docker-compose.prototype.yml up

    b. from the present `prototype` directory:

            docker-compose -f docker-compose.prototype.yml up
    
    This should bring the services up for TIGUITTO. add `-d` flag to detach the stack logs

5. Create `admin` user for InfluxDB and give `telegraf` user all privileges. (from the shell, whereever you are):

    a. Create `admin` user with all privileges

            curl -G 'http://localhost:8086/query' --data-urlencode "q=CREATE USER admin WITH PASSWORD 'tiguitto' WITH ALL PRIVILEGES"

    b. Give `telegraf` user all privileges

            curl -G 'http://localhost:8086/query' \
                -u admin:tiguitto \
                --data-urlencode "q=CREATE USER telegraf WITH PASSWORD 'tiguitto' WITH ALL PRIVILEGES"

    This will allow Telegraf to insert data into the dedicated database

6. Grafana Should be available on http://localhost:3000/login with the following credentials:

        username: admin
        password: tiguitto
    
    You can use the InfluxDB credentials created in Step 4 to create an InfluxDB Datasource in Grafana

### Component Logs

- For `mosquitto`:

        cat mosquitto/log/mosquitto.log

- For `telegraf`, `influxdb`, `grafana`:

    a. from root directory:

        docker-compose -f prototype/docker-compose.prototype.yml logs -f telegraf
        # OR
        docker-compose -f prototype/docker-compose.prototype.yml logs -f influxdb
        # OR
        docker-compose -f prototype/docker-compose.prototype.yml logs -f grafana

    b. from `prototype` (this) directory:

        docker-compose -f docker-compose.prototype.yml logs -f telegraf
        # OR
        docker-compose -f docker-compose.prototype.yml logs -f influxdb
        # OR
        docker-compose -f docker-compose.prototype.yml logs -f grafana

---

## Ports for Components

| Component   | Port  |
| ----------  | ----- |
| `influxdb`  | 8086  |
| `telegraf`  | n/a   |
| `grafana`   | 3000  |
| `mosquitto` | 1883 |

---

## Component Level Security

### Mosquitto MQTT Broker

The `mosquitto/config/passwd` file has two users in it:


|   username  |  password  |                         role                         |
|:-----------:|:----------:|:----------------------------------------------------:|
| `pubclient` | `tiguitto` | Publishing Data to MQTT Broker. For IoT Sensor Nodes |
| `subclient` | `tiguitto` |       Subscribing to MQTT Broker. For Telegraf       |

The file needs to be encrypted in order for the Broker to accept it. Passwords in Mosquitto cannot be plain-text.

See Step 1 for Reference

### Telegraf

The configuration file (`telegraf.conf`) will use the following environment variables to write data into
InfluxDB

    INFLUX_USERNAME=telegraf
    INFLUX_PASSWORD=tiguitto

The data will be written to a database called `edge` (change the name in the `telegraf.conf` accordingly)

Telegraf will use the following environment variables to subscribe to Mosquitto Broker

    TG_MOSQUITTO_USERNAME=subclient
    TG_MOSQUITTO_PASSWORD=tiguitto

### InfluxDB

> Since InfluxDB does not provide Environment Variables to setup an `admin` user, one needs to use `curl` to setup privileges

See Step 4 for Reference

### Grafana

Grafana container will use the following environment variables to set up an admin account

    GF_ADMIN_USERNAME=admin
    GF_ADMIN_PASSWORD=tiguitto
