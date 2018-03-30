#!/bin/bash

# Helper script to update configuration for existing and running
# lxd containter deployments and restart them to apply the changes

LXD_PROFILE=$1

for machine in $(juju list-machines | awk 'NR >1 {print $1}' | grep -v lxd | paste -sd' '); do
    echo "Updating profile for machine $machine..."
    juju scp $LXD_PROFILE $machine:~
    juju ssh $machine "cat $LXD_PROFILE | sudo lxc profile edit default"
    for container in $(juju list-machines | awk '$1 ~ /^'$machine'/ {print $4}' | grep lxd | paste -sd' '); do
    echo "Restarting container $container at machine $machine..."
        juju ssh $machine "sudo lxc restart $container"
    done
    echo "Done"
done
