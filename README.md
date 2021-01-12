# ethminer_watchdog

Run a watchdog on top of [`ethminer`](https://github.com/ethereum-mining/ethminer/)

![Screenshot](/docs/screenshot.png)

## What is this?

For a long time I was experimenting with some kind of a watchdog that would
restart my miners during internet outages, connection timeouts etc.
After some time I've ended up with this script has worked well for me now for
couple of months already.

## How to run

```
./ethminer_watchdog.sh
```

Required environment variables to set:

 * `ETHMINER` - path to ethminer binary; default: `ethminer`
 * `ETHMINER_POOL_URL` - pool URL to use

## Limitations

* For now it runs only on Linux with `gdm` as display manager
  (mostly because of `nvidia-settings` behavior)

