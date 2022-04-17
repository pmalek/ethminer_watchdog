# ethminer_watchdog

Run a watchdog on top of [`ethminer`](https://github.com/ethereum-mining/ethminer/)

![Screenshot](/docs/screenshot.png)

## What is this?

For a long time I was experimenting with some kind of a watchdog that would
restart my miners during internet outages, connection timeouts etc.
After some time I've ended up with this script has worked well for me now for
couple of months already.

## How to run

### From the terminal

```
./ethminer_watchdog.sh
```

Required environment variables to set:

- `ETHMINER` - path to ethminer binary; default: `ethminer`
- `ETHMINER_POOL_URL` - pool URL to use

### As a `systemd` service

In order to run ethminer_watchdog as a `systemd` service you can use the following systemd unit file:

```systemd
[Unit]
Description=Ethminer systemd unit

[Service]
Type=simple
ExecStart=<path_to_ethminer_watchdog.sh>
User=<your_username>
Environment=FAN_SPEED=66
Environment=POWER_LIMIT=95
Environment=ETHMINER=<path_to_ethminer>
Environment=ETHMINER_POOL_URL=<your_miners_address>

RestartSec=10
Restart=on-failure

ProtectSystem=strict
ProtectHome=read-only
PrivateTmp=true
TasksMax=16

[Install]
WantedBy=default.target
```

You can run it as a `system` service by placing the above snippet in e.g. `/etc/systemd/system/ethminer.service` and reloading the `systemd` daemon:

```shell
sudo systemctl daemon-reload
```

## Limitations

- For now it runs only on Linux with `gdm` as display manager
  (mostly because of `nvidia-settings` behavior)
