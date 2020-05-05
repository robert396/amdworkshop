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

## Examples

Within the `examples/` directory there are two deployment configurations for a `hello world` application.

The first example called `basic`, uses the standard Kubernetes manifest `yaml` files.

The second example called `hello-world-chart` is a Helm chart, which builds the manifest files from templates.

### Basic

In the basic example located at `examples/basic` you will find three files.

```
deployment.yaml
ingress.yaml
service.yaml
```

The manifest files as they are can be used to deploy the app into the `default` namespace and expose it on https://amd-wks.quartex.uk, but we don't want to do that.

For this example we are going to look at creating a new `namespace`, changing the `hostname` for the app, and then deploying.

Step 1. Create the new namespace

Creating a new namespace to deploy resources to in a kubernetes cluster is quite simple, just a single command.

NOTE: The namespace name must be in lowercase.

```sh
kubectl create namespace <name>
```

To check that the namespace was created successfully you can get a list of namespaces in the cluster by calling:

```sh
kubectl get namespaces
```

Step 2. Updating the Manifest files

The first file we are going to change is the `deployment.yaml` file, open it and find line `8`.

Change the value of the namespace to the one we created in step 1, and then save the file.

```yaml
namespace: <name>
```

Next we are going to edit the `ingress.yaml` file, open it and change the namespace on line `12` and then locate line `19`.

Here we are going to change out the `host` from `amd-wks.quartex.uk` to a more personal one.

NOTE: Do not use a hostname that matches a currently deployed `front-end` application and it must end in `quartex.uk`, so use something completely unique like `john-wks.quartex.uk` 

```yaml
  - host: '<name>.quartex.uk'
```

And finally we are going to open the `service.yaml` file and change the namespace on line `8`.

Step 3. Applying the manifests

In order for the cluster to have any idea of our resources, we actually need to apply the files. With Kubernetes this can be done all at once or singularly by using the `apply` sub-command.

One by One:

```sh
kubectl apply -f ./deployment.yaml
kubectl apply -f ./ingress.yaml
kubectl apply -f ./service.yaml
```

All at once (applies all yaml files in the directory):

```sh
kubectl apply -f ./
```

#### Clean Up

Deleting any created resources via the manifest files is as simple as running the `delete` sub-command instead of `apply`

One by One:

```sh
kubectl delete -f ./deployment.yaml
kubectl delete -f ./ingress.yaml
kubectl delete -f ./service.yaml
```

All at once (deletes all resources based on yaml files in the directory):

```sh
kubectl delete -f ./
```

### Helm Chart

Deploying the helm chart is quite a bit easier, as all the necessary files are templated, we just need to create a single yaml file with some of the necessary information.

```yaml
ingress:
  hosts:
    - host: john-wks.quartex.uk
      paths: ['/']
```

Save this yaml into a file somewhere that you can access, as we are going to be using it in just a moment.

For reference my file is saved at the root of this repo (where the README.md file is located) with a name of `values.yaml`

So to install this chart we are going to run the following command:

NOTE: The `releaseName` must be unique for this release, if you use a pre-existing name then it will be rejected, so use something similar to the host name like `john-wks`

```sh
helm install --name <releaseName> ./examples/hello-world-chart -f values.yaml --namespace <yourNamespace>
```

This will compile the necessary manifest templates using the supplied values, and the chart default values and apply those manifests against the cluster to create those resources.

To update an existing release use the following:

```sh
helm upgrade <releaseName> ./examples/hello-world-chart -f values.yaml
```

#### Clean Up

Deleting a release from Helm is quite nice and simple:

```sh
helm delete --purge <releaseName>
```