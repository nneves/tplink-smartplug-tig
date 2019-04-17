# TODO List

* [x] Run docker container to simulate a smartplug
* [x] Grafana initialization should allow to import base Graphs
* [x] Grafana initialization: check for grafana first launch, setup initialization procedure to add user,pw
* [ ] Fix: datacollector from emulator should return error when no emulator data returns
* [ ] Create bash script library to add/remove data from SMARTPLUG/device.list file
* [ ] Post slack message in the smartcolector_manager script, when adding or removing a datacolector container
* [ ] InfluxDB: set default policy to expire data
* [ ] Linux service install script (sudo service smartplug start)
* [ ] Smartplug update service, checks repo for updates, git pull and restart (explicit UPDATE flag required)
* [ ] Smartplug.sh: set option to configure .env file (SLACK_WEBHOOK, ENERGY_COST_PER_KWH, etc)
* [ ] InfluxDB: pass ENERGY_COST_PER_KWH env var to influxdb
* [ ] InfluxDB: use ENERGY_COST_PER_KWH to calculate costs metrics over each smartplug metric