#!/bin/bash

openstack overcloud container image prepare   \
  --namespace docker-registry.engineering.redhat.com/rhosp13  \
  --prefix "openstack-" \
  --tag 2018-03-16.1 \
  --env-file docker_registry.yaml \
  --service-environment-file /usr/share/openstack-tripleo-heat-templates/environments/docker.yaml
