# Run Fedora CoreOS using virsh/libvirt

## How to use?

```shell
$ git clone https://github.com/praveenkumar/fcos-libvirt.git && cd fcos-libvirt.git

$ ./run_fcos.sh -h
run_fcos.sh [[create | start | stop | delete] | [-h]]

where:
    create - Create the cluster resources
    start  - Start the cluster
    stop   - Stop the cluster
    delete - Delete the cluster
    -h     - Usage message

$ ./run_fcos.sh create

$ ./run_fcos.sh start
```

- This repo contain `fedora.yaml` file which you can use with Fedora CoreOS config Transpiler (fcct)  https://github.com/coreos/fcct to
generate the `fedora.ign` file. Current `fedora.ign` file is generated using same tool.

- Right now we are directly downloading the fedora coreos qcow2 image with a hardcoded link so if you want to try out some different link then
download it manually with file name `fedora-coreos.qcow2` so it will not overwritten.
