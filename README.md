# Run Fedora CoreOS using virsh/libvirt

[![asciicast](https://asciinema.org/a/260843.svg)](https://asciinema.org/a/260843)

## How to use?

```shell
$ git clone https://github.com/praveenkumar/fcos-libvirt.git && cd fcos-libvirt.git

$ ./run_fcos.sh -h
run_fcos.sh [[create | start | stop | delete] | [-h]]

where:
    create - Create the fcos resources
    start  - Start the fcos vm
    stop   - Stop the fcos vm
    delete - Delete the fcos vm
    -h     - Usage message

$ ./run_fcos.sh create

$ ./run_fcos.sh start
```

- This repo contain `fedora.yaml` file which you can use with Fedora CoreOS config Transpiler (fcct)  https://github.com/coreos/fcct to
generate the `fedora.ign` file. Current `fedora.ign` file is generated using same tool.

- Fedora coreos qcow2 image is downloaded from https://builds.coreos.fedoraproject.org/streams/testing.json so if you want to try out some different stream then
update that link manually, downloaded filename is `fedora-coreos.qcow2`.

- Default password is set to `test` as part of ignition config file.

## How to get IP of VM?

VM IP is allocated by dns server run by libvirt. Easy way to get the IP is just follow the console logs using `virsh console <VM_ID>` and once the
VM is started it print IP on the console.
