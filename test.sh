#!/usr/bin/env bash
  K8S_SLAVES=(192.168.10.5 192.168.10.6 192.168.10.7)
  K8S_SERVERS=
  let len=${#K8S_SLAVES[*]}
  for ((i=0; i<$len; i++))
  do
      let j=$i+1
      if [ "$len" -ne "$j" ]; then
       K8S_SERVERS+="\"${K8S_SLAVES[i]}"\",
       continue
      fi
      K8S_SERVERS+=${K8S_SLAVES[i]}
      echo ${K8S_SERVERS}
  done

cat > etcd-csr.json <<EOF
  {
    "CN": "etcd",
    "hosts": [
      "127.0.0.1",
      ${K8S_SERVERS[@]}
    ],
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
        "O": "k8s",
        "OU": "4Paradigm"
      }
    ]
  }
EOF
