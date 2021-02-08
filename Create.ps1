#Create a cluster using Kubenet in a bring your own subnet
#https://docs.microsoft.com/en-us/azure/aks/configure-kubenet
#az account List-locations
#az vm list-skus --location southcentralus -o tsv
az ad sp create-for-rbac --skip-assignment
VNET_ID=$(az network vnet show --resource-group RG-Infra-SCUS --name VNet-Infra-SCUS --query id -o tsv)
SUBNET_ID=$(az network vnet subnet show --resource-group RG-Infra-SCUS --vnet-name VNet-Infra-SCUS --name AKSKubeSubnet --query id -o tsv)

az role assignment create --assignee "<appid>" --scope $VNET_ID --role "Network Contributor"

az aks create \
    --resource-group RG-AKS-Kubenet \
    --name AKS-USSC-Kubenet1 \
    --location southcentralus \
    --node-count 1 \
    --node-vm-size Standard_B2s \
    --network-plugin kubenet \
    --service-cidr 10.7.0.0/16 \
    --dns-service-ip 10.7.0.10 \
    --pod-cidr 10.244.0.0/16 \
    --docker-bridge-address 172.17.0.1/16 \
    --vnet-subnet-id $SUBNET_ID \
    --service-principal "<appid>" \
    --client-secret "<secret>" \
    --generate-ssh-keys


az aks get-credentials --resource-group RG-AKS --name aks-ussc-cni1
az aks get-credentials --resource-group RG-AKS-Kubenet --name aks-ussc-kubenet1

#View service principal for cluster
az aks show --resource-group RG-AKS --name aks-ussc-cni1 --query servicePrincipalProfile.clientId
az ad sp show --id (az aks show --resource-group RG-AKS --name aks-ussc-cni1 --query servicePrincipalProfile.clientId)

#Install kubectl then have to update path to include it
az aks install-cli

#Open a browser to the kubernetes for a cluster
az aks browse --resource-group RG-AKS --name aks-ussc-cni1

kubectl cluster-info
kubectl get nodes

kubectl apply -f azure-vote.yaml

kubectl get pods -o wide
kubectl get pods --show-labels
kubectl get service
kubectl describe svc azure-vote-front1
#note the endpoints for the frontend points to the IP of the frontend pod IP
kubectl get endpoints azure-vote-front1


#General other
kubectl get service --all-namespaces
#delete deployment
kubectl delete  -f azure-vote.yaml
