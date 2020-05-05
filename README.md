# AMD Kubernetes Workshop
Welcome to the Kubernetes Workshop for Adam Matthew Digital, in this repo you will find the necessary information to get your machine up and running with access to the Quartex Kubernetes clusters.

Included in this repo is a bash script to install the necessary command line tools and packages for accessing any of the clusters and for deploying applications.

## Requirements

1. Windows Subsystem for Linux (WSL) - Ubuntu 18.04 is recommended
2. AWS Credentials for the Quartex Account (access key, secret key)


## Getting setup

In order to get setup and gain access to the clusters you have 2 choices: run the install.sh script or run the commands manually.

### Installing via script

In the `scripts/` directory you will find a bash file called `install.sh`, in order to run the script you will need to open the WSL and navigate to the `scripts` directory.

```sh
cd amdworkshop/scripts
```

Next you will execute the bash script, passing in you AWS Access Key and AWS Secret Key.

```sh
sudo ./install.sh <accessKey> <secretKey>
```

It will take upwards of 10 minutes to install all the necessary packages.

### Installing via CLI

Open any WSL terminal and then run the following commands:

Step 1: Install the necessary linux packages via `apt`

```sh
sudo apt-get update -y && sudo apt-get install -y bash-completion nmap apt-transport-https ca-certificates curl wget gnupg-agent software-properties-common python3 python3-pip git
```

Step 2: Install the AWS CLI tool via `pip`

```sh
pip3 install --upgrade pip setuptools awscli
```

Step 3: Configure AWS CLI with your credentials

```sh
aws configure set aws_access_key_id $AWS_ACCESS_KEY
aws configure set aws_secret_access_key $AWS_SECRET_KEY
aws configure set region us-east-1
```

Verify that the aws credential have been set correctly by running `aws sts get-caller-identity`

You should get back something like this:

```json
{
    "UserId": "<accessKey>",
    "Account": "<awsAccountId>",
    "Arn": "arn:aws:iam::<awsAccountId>:user/<awsUsername>"
}
```

Step 4. Installing and configuring the Kubernetes Command Line Tool (kubectl)

```sh
sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.16.2/bin/linux/amd64/kubectl
sudo chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
```

Next add the `development` and `production` clusters to the kube config file:

```sh
aws eks --region us-east-1 update-kubeconfig --name quartex-production --alias prod
aws eks --region us-east-1 update-kubeconfig --name quartex-development --alias dev
```

You can verify that the config file is correct by running: `kubectl config view` and checking that the two clusters appear in the resulting output.

Step 5. Installing Helm (Package Manager)

```sh
sudo wget -q https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-linux-amd64.tar.gz -O - | sudo tar -xzO linux-amd64/helm > /usr/local/bin/helm
sudo chmod +x /usr/local/bin/helm
helm completion bash | sudo tee /etc/bash_completion.d/helm > /dev/null
helm init --client-only
helm repo add quartex http://clusters.quartex.uk:5208
helm repo add spotinst https://spotinst.github.io/spotinst-kubernetes-helm-charts
helm repo update
```

Step 6 (Optional). Installing some additonal management tools

The first tool is Kubectx which makes it easier to change the currently set context for kubectl, this can help changing between the `dev` and `prod` clusters easier.

```sh
sudo curl -O https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx && chmod +x kubectx && sudo mv kubectx /usr/local/bin/
BASE_URL=https://raw.githubusercontent.com/ahmetb/kubectx/master/completion
sudo curl ${BASE_URL}/kubectx.bash | sudo tee /etc/bash_completion.d/kubectx > /dev/null
```

You can change the current context by running: 
```sh
kubectx <contextName>
```
For example to change to the dev cluster 
```sh
kubectx dev
```

The second tool is kubens which is used to change what the default namespace kubectl when getting resources from the cluster (default namespace is `default`).

```sh
sudo curl -O https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens && chmod +x kubens && sudo mv kubens /usr/local/bin/
BASE_URL=https://raw.githubusercontent.com/ahmetb/kubectx/master/completion
curl ${BASE_URL}/kubens.bash | sudo tee /etc/bash_completion.d/kubens > /dev/null
```

If you wanted to change the default namespace that you query, then run the command:
```sh
kubens <namespace>
```
For example if I wanted to always query the QA resources by default in the `dev` cluster then I would run 
```sh
kubens qa
```
