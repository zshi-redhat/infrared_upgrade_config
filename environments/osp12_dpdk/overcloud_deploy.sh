#!/bin/bash

openstack overcloud deploy \
    --templates \
    -r /home/stack/osp12_dpdk/roles_data.yaml \
    --timeout 90 \
    -e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
    -e /usr/share/openstack-tripleo-heat-templates/environments/neutron-ovs-dpdk.yaml \
    -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
    -e /usr/share/openstack-tripleo-heat-templates/environments/docker.yaml \
    -e /usr/share/openstack-tripleo-heat-templates/environments/docker-ha.yaml \
    -e /home/stack/osp12_dpdk/network-environment.yaml \
    -e /home/stack/docker_registry.yaml
    --ntp-server 10.5.26.10 \
    --log-file overcloud_install.log
