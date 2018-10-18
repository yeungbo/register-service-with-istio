#!/bin/bash
# uncomment to debug the script
# Register service access endpoint with ISTIO service for WH service deployed on SDT K8S cluster
# author: Bo Yang, yangbbo@cn.ibm.com 
set -xe

# Input env variables (can be received via a pipeline environment properties).
#echo "DEPLOYMENT_NAME=${DEPLOYMENT_NAME}"
echo "BASE_URL=${BASE_URL}"
echo "SERVICE_NAME=${SERVICE_NAME}"
echo "CLUSTER_NAMESPACE=${CLUSTER_NAMESPACE}"
echo "ACCESS_ENDPOINT_NAME=${ACCESS_ENDPOINT_NAME}"

if [ -z "${ACCESS_ENDPOINT_NAME}" ]; then
  echo -e "Property ACCESS_ENDPOINT_NAME:"${ACCESS_ENDPOINT_NAME}" is not set"
  exit 1
fi

if [ -z "${SERVICE_NAME}" ]; then
  echo -e "Property SERVICE_NAME:"${SERVICE_NAME}" is not available or provided"
  exit 1
fi

cat ${SERVICE_NAME}.yaml

#Check target availability
echo "=========================================================="
echo "CHECKING TARGET service readiness and namespace existence"

if kubectl get namespace | grep ${CLUSTER_NAMESPACE}; then
  echo -e "Namespace ${CLUSTER_NAMESPACE} found."
else
  echo -e "Namespace ${CLUSTER_NAMESPACE} doesn't exist."
  exit 1
fi

#if kubectl get deploy -n ${CLUSTER_NAMESPACE}| grep ${DEPLOYMENT_NAME}; then
#  echo -e "Deployment ${DEPLOYMENT_NAME} found."
#else
#  echo -e "Deployment ${DEPLOYMENT_NAME} doesn't exist."
#  exit 1
#fi

if kubectl get svc -n ${CLUSTER_NAMESPACE}| grep ${SERVICE_NAME}; then
  echo -e "Service ${SERVICE_NAME} found."
else
  echo -e "Service ${SERVICE_NAME} doesn't exist."
  exit 1
fi



echo "=========================================================="

TARGET_PORT=$(kubectl get svc ${SERVICE_NAME}  -n ${CLUSTER_NAMESPACE} -o yaml | grep "port:" | awk '{ print $3 }')
if [ -z "${TARGET_PORT}" ]; then
  echo -e "Port definition format is different...... try again"
  TARGET_PORT=$(kubectl get svc ${SERVICE_NAME}  -n ${CLUSTER_NAMESPACE} -o yaml | grep "port:" | awk '{ print $2 }')
fi

sed -i "s/SERVICE-PORT/${TARGET_PORT}/g" ${SERVICE_NAME}.yaml
sed -i "s/SERVICE-STAGENAME/${ACCESS_ENDPOINT_NAME}/g" ${SERVICE_NAME}.yaml
sed -i "s/SERVICE-NAME-IN-NAMESPACE/${SERVICE_NAME}/g" ${SERVICE_NAME}.yaml
sed -i "s/NAMESPACE/${CLUSTER_NAMESPACE}/g" ${SERVICE_NAME}.yaml
sed -i "s/PROJECT-NAME/${ACCESS_ENDPOINT_NAME}/g" ${SERVICE_NAME}.yaml

cat ${SERVICE_NAME}.yaml

kubectl apply -f ${SERVICE_NAME}.yaml -n sdt-whct-istio1-workspace-ns

if kubectl get virtualservice -n sdt-whct-istio1-workspace-ns | grep ${ACCESS_ENDPOINT_NAME}; then
  echo -e "ACCESS ENDPOINT $BASE_URL/${ACCESS_ENDPOINT_NAME} is created successful."
else
  echo -e "ACCESS ENDPOINT $BASE_URL/${ACCESS_ENDPOINT_NAME} is created failed."
  exit 1
fi



