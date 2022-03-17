#!/bin/bash
ENV_TYPE=$1
PROJECT_NAME=$2
LABLE_TYPE=""
LOG_PATH=""

if [ "${ENV_TYPE}" = "dev" ] || [ "${ENV_TYPE}" = "sit" ];then
  LABLE_TYPE="${ENV_TYPE}"
  LOG_PATH="/logs/${ENV_TYPE}/${PROJECT_NAME}/*/*.log"
fi

if [ "${ENV_TYPE}" = "uat-cn" ];then
  LABLE_TYPE="uatcn"
  LOG_PATH="/ops/logs/${ENV_TYPE}/${PROJECT_NAME}/*/*.log"
fi

if [ "${ENV_TYPE}" = "poc" ];then
  LABLE_TYPE="poc"
  LOG_PATH="/ops/logs/${ENV_TYPE}/${PROJECT_NAME}/*/*.log"
fi

if [ "${ENV_TYPE}" = "uat-us" ];then
  LABLE_TYPE="uatus"
  LOG_PATH="/logs/${ENV_TYPE}/${PROJECT_NAME}/*/*.log"
fi

if [ "${ENV_TYPE}" = "pro-cn" ];then
  LABLE_TYPE="procn"
  LOG_PATH="/logs/${PROJECT_NAME}/*/*.log"
fi

if [ "${ENV_TYPE}" = "pro-us" ];then
  LABLE_TYPE="prous"
  LOG_PATH="/logs/${PROJECT_NAME}/*/*.log"
fi

#/ops/common/plg/promtail/conf/promtail.yml
cat >> promtail-c-dev-test.yml << EOF
- job_name: ${ENV_TYPE}-${PROJECT_NAME}
  static_configs:
  - targets:
      - localhost
    labels:
      ${LABLE_TYPE}: ${PROJECT_NAME}
      __path__: ${LOG_PATH}
EOF

cat >> /ops/common/plg/promtail/conf/promtail.yml << EOF
- job_name: ${ENV_TYPE}-${PROJECT_NAME}
  static_configs:
  - targets:
      - localhost
    labels:
      ${LABLE_TYPE}: ${PROJECT_NAME}
      __path__: ${LOG_PATH}
EOF

