#!/bin/sh
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
curl -sL https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
    sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update -y
sudo apt-get install azure-cli

# Install Kubectl
sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2 curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubectl

# Install Helm
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update -y
sudo apt-get install helm -y


# Install .net core

wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

sudo apt-get update;  sudo apt-get install -y apt-transport-https &&   sudo apt-get update &&   sudo apt-get install -y dotnet-sdk-3.1

sudo apt-get update; sudo apt-get install -y apt-transport-https && sudo apt-get update && sudo apt-get install -y aspnetcore-runtime-3.1


# Generate SSH key

ssh-keygen -m PEM -t rsa -b 4096 -C "azureuser@myserver" -f /root/.ssh/id_rsa -N ""


az login --identity
az keyvault secret set --name test --vault-name $1 --file ~/.ssh/id_rsa.pub