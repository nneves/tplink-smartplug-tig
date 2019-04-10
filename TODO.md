# TODO List

* [ ] Linux service install script (sudo service smartplug start)
* [ ] Run docker container to simulate a smartplug
* [ ] Smartplug update service, checks repor for updates, git pull and restart (explicit UPDATE flag required)
* [ ] Grafana initialization should allow to import base Graphs (custom init flag, script should check if grafana folder is empty)
* [ ] Grafana initialization: check for grafana first launch, setup initialization procedure to add user,pw
* [ ] InfluxDB: set default policy to expire data
* [ ] Smartplug.sh: set option to configure .env file (SLACK_WEBHOOK, ENERGY_COST_PER_KWH, etc)
* [ ] InfluxDB: pass ENERGY_COST_PER_KWH env var to influxdb
* [ ] InfluxDB: use ENERGY_COST_PER_KWH to calculate costs metrics over each smartplug metric