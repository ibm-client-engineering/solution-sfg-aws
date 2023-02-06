<h1>IBM Client Engineering - Solution Document</h1>

<h2>Solution Name</h2>
<img align="right" src="https://user-images.githubusercontent.com/95059/166857681-99c92cdc-fa62-4141-b903-969bd6ec1a41.png" width="491" >


# Introduction and Goals

## Background and Business Problem


# Solution Strategy

## Overview

## Building Block View

## Deployment
### Pre-Requisites
#### **AWS Account:** This presumes you have an AWS Account and `aws` cli configured.

#### **EKS Cluster**

The first tool we will use is called `eksctl`.
### Installing or updating `eksctl` 
MacOS: Install `eksctl` via Homebrew

If you don't have homebrew installed, run these commands in a terminal window:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

brew upgrade eksctl && { brew link --overwrite eksctl; } || { brew tap weaveworks/tap; brew install weaveworks/tap/eksctl; }
```
Verify the install with 

```
eksctl version
```
**To install or update eksctl on Linux**

Download and extract the latest release of eksctl with the following command.
```
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
```
Move the extracted binary to /usr/local/bin.
```
sudo mv /tmp/eksctl /usr/local/bin
```
Test that your installation was successful with the following command.
```
eksctl version
```
Run the `eksctl` command below to create your first cluster and perform the following:

-   Create a 6-node Kubernetes cluster named `mft-sterling-east` with one node type as `m5.xlarge` and region as `us-east-1`.
-   Define a node group named `standard-workers`.
-   Select a machine type for the `standard-workers` node group.
-   Specify our three AZs as `us-east-1a, us-east-1b, us-east-1c`
```
eksctl create cluster \
--name <CLUSTERNAME> \
--version 1.23 \
--region us-east-1 \
--zones us-east-1a,us-east-1b,us-east-1c \
--nodegroup-name standard-workers \
--node-type m5.xlarge \
--nodes 6 \
--nodes-min 1 \
--nodes-max 6 \
--managed
```

Associate an IAM oidc provider with the cluster
```
eksctl utils associate-iam-oidc-provider --region=us-east-1 --cluster=mft-sterling-east --approve
```
Once the cluster is up, add it to your kube config
```
aws eks update-kubeconfig --name mq-cluster-east --region us-east-1
Added new context arn:aws:eks:us-east-1:748107796891:cluster/mq-cluster to /Users/kramerro/.kube/config
```
- RDS/DB Schema
- Registry - images
#### **Trial sign-up for Sterling MFT**
- Using your IBM ID, submit for SFG trial request using: https://www.ibm.com/account/reg/us-en/signup?formid=urx-51433
- Use the access token for IBM Entitled Registry from Step 1 to pull and stage images (in their internal image repository, if necessary).
- Charts: https://github.com/IBM/charts/blob/master/repo/ibm-helm/ibm-sfg-prod.md
 https://github.com/IBM/charts/blob/master/repo/ibm-helm/ibm-sfg-prod-2.1.1.tgz
## Security

## Cost

## Risks and Technical Debts

## Testing

# Architecture Decisions
