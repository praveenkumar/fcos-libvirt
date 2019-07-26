#!/bin/sh

set +x

prerequisites()
{  
    # Check if virtualization is supported
    ls /dev/kvm 2> /dev/null
    if [ $? -ne 0 ]
    then
        echo "Your system doesn't support virtualization"
        exit 1
    fi

    # Install required dependecies
    sudo yum install -y libvirt libvirt-devel libvirt-daemon-kvm qemu-kvm
    
    # Download the fedora coreos image if not available
    if [ ! -f fedora-coreos.qcow2 ]; then
	curl -L -O https://builds.coreos.fedoraproject.org/prod/streams/testing/builds/30.20190725.0/x86_64/fedora-coreos-30.20190725.0-qemu.qcow2.xz
	unxz -d fedora-coreos-30.20190725.0-qemu.qcow2.xz
	mv fedora-coreos-30.20190725.0-qemu.qcow2 fedora-coreos.qcow2
    fi

    # Start the libvirtd service
    sudo systemctl start libvirtd

    # Configure default libvirt storage pool
    sudo virsh pool-info 'default'
    if [ $? -ne 0 ]
    then
        sudo virsh pool-define /dev/stdin <<EOF
<pool type='dir'>
  <name>default</name>
  <target>
    <path>/var/lib/libvirt/images</path>
  </target>
</pool>
EOF
    sudo virsh pool-start default
    sudo virsh pool-autostart default
    fi
}

cluster_create()
{
    size=$(stat -Lc%s fedora-coreos.qcow2)
    sudo virsh vol-create-as default fedora-coreos $size --format qcow2
    sudo virsh vol-upload --sparse --pool default fedora-coreos fedora-coreos.qcow2

    size=$(stat -Lc%s fedora.ign)
    sudo virsh vol-create-as default fedora.ign $size --format raw
    sudo virsh vol-upload --pool default fedora.ign fedora.ign

    # Fix the raw file permission to read by qemu
    sudo chmod 0644 /var/lib/libvirt/images/fedora.ign

    sudo virsh define /dev/stdin  << EOF
<domain type="kvm" xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <name>fcos</name>
  <memory>2097152</memory>
  <currentMemory>2097152</currentMemory>
  <vcpu>2</vcpu>
  <os>
    <type arch="x86_64" machine="q35">hvm</type>
    <boot dev="hd"/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode='host-passthrough' check='none'/>
  <clock offset="utc"/>
  <devices>
    <disk type="file" device="disk">
      <driver name="qemu" type="qcow2"/>
      <source file="/var/lib/libvirt/images/fedora-coreos"/>
      <target dev="vda" bus="virtio"/>
    </disk>
    <interface type="network">
      <source network="default"/>
      <mac address="52:54:00:f2:d5:ee"/>
      <model type="virtio"/>
    </interface>
    <console type="pty"/>
    <channel type="unix">
      <source mode="bind"/>
      <target type="virtio" name="org.qemu.guest_agent.0"/>
    </channel>
    <rng model="virtio">
      <backend model="random">/dev/urandom</backend>
    </rng>
  </devices>
  <qemu:commandline>
    <qemu:arg value='-fw_cfg'/>
    <qemu:arg value='name=opt/com.coreos/config,file=/var/lib/libvirt/images/fedora.ign'/>
  </qemu:commandline>
</domain>
EOF
    echo "Fedora CoreOS Domain created successfully use '$0 start' to start it"
}


cluster_start()
{
    sudo virsh start fcos
    echo "Feodra CoreOS domain started"
}


cluster_stop()
{
    sudo virsh shutdown fcos
    echo "Fedora CoreOS domain stopped"
}


cluster_delete()
{
    sudo virsh destroy fcos
    sudo virsh undefine fcos
    
    sudo virsh vol-delete --pool default fedora-coreos
    sudo virsh vol-delete --pool default fedora.ign
}


usage()
{
    usage="$(basename "$0") [[create | start | stop | delete] | [-h]]

where:
    create - Create the cluster resources
    start  - Start the cluster
    stop   - Stop the cluster
    delete - Delete the cluster
    -h     - Usage message
    "

    echo "$usage"

}

main()
{
    if [ "$#" -ne 1 ]; then
        usage
        exit 0
    fi

    while [ "$1" != "" ]; do
        case $1 in
            create )           prerequisites
                               cluster_create
                               ;;
            start )            cluster_start
                               ;;
            stop )             cluster_stop
                               ;;
            delete )           cluster_delete
                               ;;
            -h | --help )      usage
                               exit
                               ;;
            * )                usage
                               exit 1
        esac
        shift
    done
}

main "$@"; exit
