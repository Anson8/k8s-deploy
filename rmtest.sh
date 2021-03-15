#!/usr/bin/env bash
sudo systemctl stop kube-nginx
rm -rf /opt/kubernetes/cfg/*
rm -rf /opt/kubernetes/ssl/*
rm -rf ~/.kube
rm -rf /etc/systemd/system/kube-nginx.service
