#!/bin/bash
ip route del default
ip -6 route del default
chown -R frr.frr /etc/frr
service frr start
sleep infinity
