#!/bin/bash

openstack overcloud deploy --templates /home/stack/tripleo-heat-templates-newton \
--control-scale 3 --compute-scale 2 --ceph-storage-scale 0 \
--control-flavor controller --compute-flavor compute \
-e /home/stack/tripleo-heat-templates-newton/environments/puppet-pacemaker.yaml \
-e /home/stack/tripleo-heat-templates-newton/environments/network-isolation.yaml \
-e /home/stack/tripleo-heat-templates-newton/environments/net-single-nic-with-vlans.yaml \
-e /home/stack/tripleo-heat-templates-newton/environments/neutron-ovs-dpdk.yaml \
-e /home/stack/rdo_newton_dpdk_uc_master_oc_newton/network-environment.yaml \
--ntp-server 10.5.26.10 \
--log-file overcloud_install.log
