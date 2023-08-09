#!/bin/bash

ip route del default
ip -6 route del default
ip route add default via $1 dev eth0
ip -6 route add default via $2 dev eth0
sleep infinity
