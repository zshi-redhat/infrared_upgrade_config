#!/bin/bash

# this script will accept parameters:
# $1: provider segment for sriov vlan
DPDK_SEGMENT=$1
PATH_TO_TEST_IMAGE=$2
LOGIN_USER=$3

source /home/stack/overcloudrc

# create zone if not exists
openstack aggregate show dpdk
ZONE_RESULT=$?

if [[ $ZONE_RESULT -ne 0 ]]; then
    openstack aggregate create --zone=sriov dpdk

    openstack aggregate add host dpdk overcloud-novacompute-0.localdomain
    openstack aggregate add host dpdk overcloud-novacompute-1.localdomain
fi

# create special flavor if not exists
openstack flavor show m1.dpdk
FLAVOR_RESULT=$?
if [[ $FLAVOR_RESULT -ne 0 ]]; then
    openstack flavor create --ram 4096 --disk 50 --vcpus 4 m1.dpdk
    openstack flavor set --property hw:cpu_policy=dedicated --property  hw:mem_page_size=large m1.dpdk
fi

# create internal network if not exists
openstack network show default
DEFAULT_NETWORK_RESULT=$?
if [[ $DEFAULT_NETWORK_RESULT -ne 0 ]]; then
    openstack network create default
    openstack subnet create default --network default --gateway 172.30.1.1 --subnet-range 172.30.0.0/16
fi

# create external network if not exists
openstack network show external
EXTERNAL_NETWORK_RESULT=$?
if [[ $EXTERNAL_NETWORK_RESULT -ne 0 ]]; then
    openstack network create --external --provider-network-type flat --provider-physical-network datacentre external
    openstack subnet create external --network external --dhcp --allocation-pool start=10.9.88.90,end=10.9.88.95 --gateway 10.9.88.254 --subnet-range 10.9.88.0/24
    openstack router create external
    openstack router add subnet external default
    neutron router-gateway-set external external
fi

# create dpdk network and ports if not exist
openstack network show net-dpdk
DPDK_NETWORK_RESULT=$?

if [[ $DPDK_NETWORK_RESULT -ne 0 ]]; then
    openstack network create net-dpdk --provider-network-type vlan --provider-physical-network dpdk --provider-segment $DPDK_SEGMENT
    neutron subnet-create --name net-dpdk-subnet --disable-dhcp --gateway 10.10.0.1 --allocation-pool start=10.10.0.2,end=10.10.0.50 net-dpdk 10.10.0.0/24
fi

# create image, file needs to previously exist
openstack image show centos
TEST_IMAGE_RESULT=$?
if [[ $TEST_IMAGE_RESULT -ne 0 ]];then
    openstack image create --name centos --file $PATH_TO_TEST_IMAGE --disk-format qcow2 --container-format bare
fi

# create keypair if not exists
openstack keypair show undercloud-stack
KEYPAIR_RESULT=$?
if [ $KEYPAIR_RESULT -ne 0 ]; then
    openstack keypair create --public-key /home/stack/.ssh/id_rsa.pub undercloud-stack
fi

# create security group if not exists
openstack security group show all-access
SECURITY_GROUP_RESULT=$?
if [[ $SECURITY_GROUP_RESULT -ne 0 ]]; then
    openstack security group create all-access
    openstack security group rule create --ingress --protocol icmp --src-ip 0.0.0.0/0 all-access
    openstack security group rule create --ingress --protocol tcp --src-ip 0.0.0.0/0 all-access
    openstack security group rule create --ingress --protocol udp --src-ip 0.0.0.0/0 all-access
fi

# create the vms and wait until are booted
openstack server show dpdk_vm_1
VM_1_RESULT=$?

if [[ $VM_1_RESULT -ne 0 ]]; then
    LAST_FIP_1=$(openstack floating ip create external -f value | grep 10.9.88)
    COMMAND_NOVA_1="openstack server create --availability-zone dpdk --security-group all-access --flavor m1.dpdk --key-name undercloud-stack --image centos   --nic net-id=$(neutron net-list | grep default | awk '{print $2}' ) --nic net-id=$(neutron net-list | grep dpdk | awk '{print $2}') dpdk_vm_1"
    VM_UUID_1=$($COMMAND_NOVA_1 |  awk '/id/ {print $4}' | head -n 1)
    echo "I run $COMMAND_NOVA_1, id is $VM_UUID_1"

    until [[ "$(nova show ${VM_UUID_1} | awk '/ status/ {print $4}')" == "ACTIVE" ]]; do
        sleep 1
    done
    openstack server add floating ip dpdk_vm_1 $LAST_FIP_1

    sleep 5
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${LOGIN_USER}@${LAST_FIP_1} 'sudo ip addr add 10.10.0.2/24 dev eth1'
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${LOGIN_USER}@${LAST_FIP_1} 'sudo ip link set eth1 up'
fi

openstack server show dpdk_vm_2
VM_2_RESULT=$?

if [[ $VM_2_RESULT -ne 0 ]]; then
    LAST_FIP_2=$(openstack floating ip create external -f value | grep 10.9.88)
    COMMAND_NOVA_2="openstack server create --availability-zone dpdk --security-group all-access --flavor m1.dpdk --key-name undercloud-stack --image centos   --nic net-id=$(neutron net-list | grep default | awk '{print $2}') --nic net-id=$(neutron net-list | grep dpdk | awk '{print $2}') dpdk_vm_2"
    VM_UUID_2=$($COMMAND_NOVA_2 |  awk '/id/ {print $4}' | head -n 1)
    echo "I run $COMMAND_NOVA_2, id is $VM_UUID_2"

    until [[ "$(nova show ${VM_UUID_2} | awk '/ status/ {print $4}')" == "ACTIVE" ]]; do
        sleep 1
    done
    openstack server add floating ip dpdk_vm_2 $LAST_FIP_2

    sleep 5
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${LOGIN_USER}@${LAST_FIP_2} 'sudo ip addr add 10.10.0.3/24 dev eth1'
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${LOGIN_USER}@${LAST_FIP_2} 'sudo ip link set eth1 up'
fi

# now test ping between vms
OUTPUT=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${LOGIN_USER}@${LAST_FIP_1} 'ping -q -w 1 10.10.0.3; echo "result$?"')
if [[ "$OUTPUT" == *"result1"* ]]; then
    echo "ping failed"
    exit 1
else
    echo "ping successful"
fi

OUTPUT=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${LOGIN_USER}@${LAST_FIP_2} 'ping -q -w 1 10.10.0.2; echo "result$?"')
if [[ "$OUTPUT" == *"result1"* ]]; then
    echo "ping failed"
    exit 1
else
    echo "ping successful"
fi

