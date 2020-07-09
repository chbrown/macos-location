# macos-location

Logger daemon for monitoring your macOS's location via CoreLocation updates.

Currently the only supported use case is logging to file, which is then tailed by [telegraf](https://www.influxdata.com/time-series-platform/telegraf/) (which batches metrics and sends them to an InfluxDB collector).

## Installation

Clone, compile, and install:

    git clone https://github.com/chbrown/macos-location.git
    cd macos-location
    make install

Run to allow location access (must be done interactively this one time):

    location-logger

Type Ctrl-C to exit.


## `launchd` integration

Prepare output location:

    mkdir -p /usr/local/var/log

If that fails, fix permissions (and then run the `mkdir` command again):

    sudo chown -R $USER:staff /usr/local/var/log/location.log

Install as user-level LaunchAgent and load for immediate use with `launchctl`:

    cp github.chbrown.macos-location.plist ~/Library/LaunchAgents/
    launchctl load ~/Library/LaunchAgents/github.chbrown.macos-location.plist


## Telegraf configuration

Edit `/usr/local/etc/telegraf.conf` and add the following [tail plugin](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/tail) configuration:

    [[inputs.tail]]
      files = ["/usr/local/var/log/location.log"]
      data_format = "influx"


## License

Copyright © 2017–2020 Christopher Brown.
[MIT Licensed](https://chbrown.github.io/licenses/MIT/#2017-2020).
