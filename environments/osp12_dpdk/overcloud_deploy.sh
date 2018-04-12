#!/bin/bash

openstack overcloud deploy \
    --templates \
    -r /home/stack/osp12_dpdk/roles_data.yaml \
    -p /usr/share/openstack-tripleo-heat-templates/plan-samples/plan-environment-derived-params.yaml \
    --timeout 90 \
    -e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
    -e /usr/share/openstack-tripleo-heat-templates/environments/neutron-ovs-dpdk.yaml \
    -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
    -e /usr/share/openstack-tripleo-heat-templates/environments/docker.yaml \
    -e /usr/share/openstack-tripleo-heat-templates/environments/docker-ha.yaml \
    -e registry.yaml \
    -e /home/stack/osp12_dpdk/network-environment.yaml \
    -e docker_registry.yaml
    --ntp-server pool.ntp.org \
    --log-file overcloud_install.log
