#!/bin/bash

#deactivate SF
devlink port function set pci/0000:07:00.1/98304 state inactive
sleep 1

# delete SF
devlink port del pci/0000:07:00.1/98304
sleep 1

modprobe -r mlx5_vdpa
modprobe -r vhost-vdpa
modprobe -r vdpa

# set switchdev mode
devlink dev eswitch set pci/0000:07:00.0 mode switchdev
sleep 5
devlink dev eswitch set pci/0000:07:00.1 mode switchdev
devlink dev eswitch show pci/0000:07:00.0
devlink dev eswitch show pci/0000:07:00.1

# Add a sf, 88 is sfnum
devlink port add pci/0000:07:00.1 flavour pcisf pfnum 1 sfnum 89
devlink port show

# Set SF MAC
devlink port function set pci/0000:07:00.1/98304 hw_addr fa:16:3e:9f:44:88
devlink port show

# Up and activate SF
sleep 5
ip link set dev en7f1pf1sf89 up
devlink port function set pci/0000:07:00.1/98304 state active
devlink port show

# Enable 16 tx/rx queues, eswitch mode will change it to 1
ethtool -L enp7s0f0 combined 16
ethtool -L enp7s0f1 combined 16
ethtool -L en7f1pf1sf89 combined 16

# list SF device
ls /sys/bus/auxiliary/devices/
devlink dev show

# load vdpa drivers
modprobe vdpa
modprobe vhost_vdpa
modprobe mlx5_vdpa
sleep 10

# unbind rdma and netdevice for SF device
vdpa mgmtdev show
ls /sys/bus/auxiliary/devices/mlx5_core.sf.2/mlx5_core.rdma.2/driver/unbind
ls /sys/bus/auxiliary/devices/mlx5_core.sf.2/mlx5_core.eth.2/driver/unbind
sleep 1
echo mlx5_core.rdma.2 > /sys/bus/auxiliary/devices/mlx5_core.sf.2/mlx5_core.rdma.2/driver/unbind
echo mlx5_core.eth.2 > /sys/bus/auxiliary/devices/mlx5_core.sf.2/mlx5_core.eth.2/driver/unbind

# add vdpa device
vdpa dev add name vhost-vdpa-0 mgmtdev auxiliary/mlx5_core.sf.2 max_vqp 16
vdpa dev show
ls /sys/bus/vdpa/devices/
readlink /sys/bus/vdpa/devices/vhost-vdpa-0/driver
