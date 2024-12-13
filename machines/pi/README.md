# The Pis

For the raspberry Pi instances, because of their limited computational power, it is highly adviced that you build on a different machine. This can be done by

```console
$ nixos-rebuild switch -j auto --build-host localhost --target-host root@<IP of Pi> --flake .#amber
```

To the end of the build procedure, it will try to `scp` the built
binaries to the Pi. It might complaining about failing to ssh to root. I would just make sure that I can `ssh root@<IP of Pi>` without password, and try again.
