# TIGUITTO

Highly used `Telegraf` + `InfluxDB` + `Grafana` stack with `Mosquitto` MQTT broker. Hence, the name:

```
T   I   G   UITTO
            |--(mosq)
        |--(rafana)
    |--(nfluxDB)
 |--(elegraf)
```

Created for [Medium.com Post: Creating Your IoT Node and Edge Prototype with InfluxDB, Telegraf and Docker](https://medium.com/@shantanoodesai/creating-your-iot-node-and-edge-prototype-with-influxdb-telegraf-and-docker-b16380282672)


## Setup

1. Create the following directories in the `mosquitto` directory for persistence and logs from the broker:

    ```bash
    mkdir -p mosquitto/log/
    mkdir -p mosquitto/data/
    ```
2. Change ownership of the `data` and `log` folders for the MQTT broker

    ```bash
    sudo chown -R 1883:1883 mosquitto/log/
    sudo chown -R 1883:1883 mosquitto/data/
    ```
    This should over a common error when the Mosquitto Container cannot open the log file to write (see [Mosquitto Issue #1078](https://github.com/eclipse/mosquitto/issues/1078))

3. Create a network for the complete stack using:

    ```bash
    docker network create iotstack
    ```
4. Update the `telegraf/telegraf.conf` according to the MQTT Topics you want to subscribe to under:

    ```toml
        [[inputs.mqtt_consumer]]
            topics = [ "<YOUR TOPICS HERE>" ]
    ```
5. (**Optional**) Additionally, change the regex and enum mappings to add more meta-data as tags in the InfluxDB or comment the sections out:

    ```toml

        [[processors.regex]]

        [[processors.regex.tags]]

            # use the `topic` tag to extract information from the MQTT Topic
            key = "topic"
            # Topic: IOT/<SENSOR_ID>/<measurement>
            # Extract <SENSOR_ID>
            pattern = ".*/(.*)/.*"
            # Replace the first occurrence
            replacement = "${1}"
            # Store it in tag called:
            result_key = "sensorID"

        [[processors.enum]]

        [[processors.enum.mapping]]

        # create a mapping between extracted sensorID and some meta-data
        tag = "sensorID"
        dest = "location"

        [processors.enum.mapping.value_mappings]
            "sensor1" = "kitchen"
            "sensor2" = "livingroom"

    ```
## Bringing up the stack

1. Bring the stack up using:

    ```bash
    docker-compose up -d
    ```
    this should create the necessary volumes and the data to the host from the respective containers (`influxdb`, `telegraf`, `grafana`, `mosquitto`)

2. Trace logs individually using:

    ```bash
    docker-compose logs -f <container_name>
    ```
    OR
    ```bash
    docker-compose logs -f 
    ```

## Test

Tested on: __Raspberry Pi 4 Model B 2GB RAM__

| Docker Tools |        Version                |
|:--------:|:---------------------------------:|
| `docker`         | __19.03.8__               |
| `docker-compose` | __1.25.5__                |
| `docker-py`      | __4.2.0__                 |
| `CPython`        | __3.7.3__                 |
| `OpenSSL`        | __1.1.1d__                |


### Checks

* Grafana should be available on `<IP_ADDRESS>:3000`
* InfluxDB should be available on `<IP_ADDRESS>:8086`
* InfluxDB admin should be available on `<IP_ADDRESS>:8083`
* Mosquitto broker should be avaialble on `<IP_ADDRESS>:1883`