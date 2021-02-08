#!/usr/bin/env bash
K8S_MASTER=(192.168.3.42 192.168.3.43 192.168.3.44)

  nodes=${K8S_MASTER[@]}
  SERVER_CLUSTER=
  for ip in $nodes;
  do
    SERVER_CLUSTER+="server ${ip}:6443  max_fails=3 fail_timeout=30s;"
  done
  echo "SERVER_CLUSTER==${SERVER_CLUSTER}"
