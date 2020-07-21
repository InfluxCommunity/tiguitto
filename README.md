# TIGUITTO

Highly used `Telegraf` + `InfluxDB` + `Grafana` stack with `Mosquitto` MQTT broker. Hence, the name:

```
T   I   G   UITTO
            |--(mosq)
        |--(rafana)
    |--(nfluxDB)
 |--(elegraf)
```

Initially created for [Medium.com Post: Creating Your IoT Node and Edge Prototype with InfluxDB, Telegraf and Docker](https://medium.com/@shantanoodesai/creating-your-iot-node-and-edge-prototype-with-influxdb-telegraf-and-docker-b16380282672)

## Cases
Since the stack is very often used in IoT Setups, there are three usable scenarios that are thought of:

|  CASE          |   Security    |  Usage                             |  Status           |
|:--------------:|:-------------:|:-----------------------------------|:-----------------:|
| `prototype`    | Basic Auth.   | Quick Deployments, Tests on Edge Devices |  On-Going   |
| `self-signed`  | X.509 Certificates | For Standalone Stacks for internal infrastructure | On-Going |
| `certbot`      | Let's Encrypt Certificates | For Production-Ready Cloud Deployments }| On-Going |


## Usage

clone the repository and from root directory:

    docker-compose -f <CASE>/docker-compose.<CASE>.yml up -d

Refer to `README.md` in each case directory
