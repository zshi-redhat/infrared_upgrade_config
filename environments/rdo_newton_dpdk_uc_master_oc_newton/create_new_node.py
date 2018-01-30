#!/usr/bin/env python
import json

data = json.load(open('/home/stack/instackenv.json'))

# remove all nodes
data['nodes'] = []

# create new entry for compute-1
new_node = {
    "name": "compute-1",
    "mac": "a0:36:9f:e7:c7:e4",
    "cpu": "16",
    "memory": "66560",
    "disk": "150",
    "arch": "x86_64",
    "pm_type": "pxe_ipmitool",
    "pm_user": "root",
    "pm_password": "calvin",
    "pm_addr": "10.9.87.35",
}
data['nodes'].append(new_node)

# write content to new file
with open('/home/stack/instackenv_new.json', 'w') as f:
    json.dump(data, f)
