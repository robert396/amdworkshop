#!/bin/bash

AWS_ACCESS_KEY=$1
AWS_SECRET_KEY=$2

if [ -z "$AWS_ACCESS_KEY" ]; then
    echo AWS Access Key is required
    exit 1
fi

if [ -z "$AWS_SECRET_KEY" ]; then
    echo AWS Secret Key is required
    exit 1
fi

echo Installing necessary apt packages
sudo apt-get update -y && sudo apt-get install -y bash-completion nmap apt-transport-https ca-certificates curl wget gnupg-agent \
software-properties-common python3 python3-pip git

echo Installing AWS CLI
pip3 install --upgrade pip setuptools awscli

echo Setting up AWS User Account
aws configure set aws_access_key_id $AWS_ACCESS_KEY
aws configure set aws_secret_access_key $AWS_SECRET_KEY
aws configure set region us-east-1

echo Installing kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.16.2/bin/linux/amd64/kubectl
chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

echo Creating kube config
aws eks --region us-east-1 update-kubeconfig --name quartex-development --alias dev
aws eks --region us-east-1 update-kubeconfig --name quartex-production --alias prod

echo Installing Helm
sudo wget -q https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-linux-amd64.tar.gz -O - | sudo tar -xzO linux-amd64/helm > /usr/local/bin/helm
sudo chmod +x /usr/local/bin/helm
helm completion bash | sudo tee /etc/bash_completion.d/helm > /dev/null
helm init --client-only
helm plugin install https://github.com/sagansystems/helm-github.git
helm plugin install https://github.com/rimusz/helm-tiller
helm plugin install https://github.com/maorfr/helm-restore
helm plugin install https://github.com/chartmuseum/helm-push
helm repo add quartex https://clusters.quartex.uk:5208
helm repo add spotinst https://spotinst.github.io/spotinst-kubernetes-helm-charts
helm repo update

echo Installing kubectx and kubens
curl -O https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx && chmod +x kubectx && sudo mv kubectx /usr/local/bin/
curl -O https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens && chmod +x kubens && sudo mv kubens /usr/local/bin/
BASE_URL=https://raw.githubusercontent.com/ahmetb/kubectx/master/completion
curl ${BASE_URL}/kubectx.bash | sudo tee /etc/bash_completion.d/kubectx > /dev/null
curl ${BASE_URL}/kubens.bash | sudo tee /etc/bash_completion.d/kubens > /dev/null
kubectx dev
echo Current kube context is
kubectx -c

echo Kubernetes and Helm have been installed.