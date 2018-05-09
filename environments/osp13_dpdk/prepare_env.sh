#!/bin/bash

set -x

# TODO workaround to bring up br-ex after overcloud deployment
# this shall be done by deployment itself
source ~/stackrc; for address in $(openstack server list -f json | jq -r -c '.[] | .Networks' | grep -oP '[0-9.]+'); do ssh -q -o StrictHostKeyChecking=no heat-admin@$address 'sudo ifconfig br-ex up; sudo dhclient -v br-ex'; done

source /home/stack/overcloudrc.v3

glance image-create --name centos --disk-format qcow2 --container-format bare --file /home/stack/centos.qcow2
sleep 1

openstack keypair create --public-key /home/stack/.ssh/id_rsa.pub undercloud-stack
sleep 60

heat stack-create -f /home/stack/osp13_dpdk/vms.yaml demo

while true
do
	sleep 5
	result=`heat stack-list | awk '/CREATE/ {print $6}'`
	if [ $result == 'CREATE_FAILED' ]; then
		echo "DEMO stack create failed!"
		exit
	elif [ $result == 'CREATE_COMPLETE' ]; then
		echo "DEMO stack create complete!"
		break
	else
		echo "DEMO stack create in progress"
	fi
	
done

sleep 300

# vnf1
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null centos@10.9.88.116 'sudo ip link set eth1 up'
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null centos@10.9.88.116 'sudo ip addr add 10.10.0.3 dev eth1'
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null centos@10.9.88.116 "printf 'ONBOOT=yes\nDEVICE=eth1\nNM_CONTROLLED=yes\nBOOTPROTO=static\nIPADDR=10.10.0.3\nNETMASK=255.255.255.0' | sudo tee /etc/sysconfig/network-scripts/ifcfg-eth1"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null centos@10.9.88.116 'sudo ifup eth1'

# vnf2
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null centos@10.9.88.117 'sudo ip link set eth1 up'
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null centos@10.9.88.117 'sudo ip addr add 10.10.0.4 dev eth1'
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null centos@10.9.88.117 "printf 'ONBOOT=yes\nDEVICE=eth1\nNM_CONTROLLED=yes\nBOOTPROTO=static\nIPADDR=10.10.0.4\nNETMASK=255.255.255.0' | sudo tee /etc/sysconfig/network-scripts/ifcfg-eth1"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null centos@10.9.88.117 'sudo ifup eth1'

# vnfm
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null centos@10.9.88.118 'sudo ip link set eth1 up'
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null centos@10.9.88.118 'sudo ip addr add 10.10.0.10 dev eth1'
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null centos@10.9.88.118 "printf 'ONBOOT=yes\nDEVICE=eth1\nNM_CONTROLLED=yes\nBOOTPROTO=static\nIPADDR=10.10.0.10\nNETMASK=255.255.255.0' | sudo tee /etc/sysconfig/network-scripts/ifcfg-eth1"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null centos@10.9.88.118 'sudo ifup eth1'


# continuously ping test between vms and output to file
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null centos@10.9.88.116 "ping 10.10.0.4 &> /tmp/pingtest_output &"
