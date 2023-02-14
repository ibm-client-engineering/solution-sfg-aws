<h1>IBM Client Engineering - Solution Document</h1>

<h2>IBM Sterling: Cloud Ready Data Exchange</h2>
<img align="right" src="https://user-images.githubusercontent.com/95059/166857681-99c92cdc-fa62-4141-b903-969bd6ec1a41.png" width="491" >

- [Introduction and Goals](#introduction-and-goals)
- [Solution Strategy](#solution-strategy)
  - [Overview](#overview)
  - [Building Block View](#building-block-view)
  - [Deployment](#deployment)
    - [Pre-Requisites](#pre-requisites)
      - [Generic Requirements](#generic-requirements)
        - [Trial sign-up for Sterling MFT](#trial-sign-up-for-sterling-mft)
      - [AWS Account](#aws-account)
      - [AWS CLI Install](#aws-cli-install)
      - [AWS EKS Cluster](#aws-eks-cluster)
      - [Installing or updating `eksctl`](#installing-or-updating-eksctl)
      - [Granting Additional Access](#granting-additional-access)
      - [Elastic File Service (EFS) on EKS](#elastic-file-service-efs-on-eks)
      - [Create an IAM policy and role](#create-an-iam-policy-and-role)
      - [Deploy Amazon EFS CSI driver to an Amazon EKS cluster](#deploy-amazon-efs-csi-driver-to-an-amazon-eks-cluster)
      - [Add Security Policies](#add-security-policies)
      - [Security Policies](#security-policies)
      - [Helm Chart installation](#helm-chart-installation)
      - [RDS/DB Schema](#rdsdb-schema)
      - [Images and Internal Registry](#images-and-internal-registry)
      - [**Install NGINX Ingress**](#install-nginx-ingress)
    - [Installation](#installation)
  - [Security](#security)
  - [Testing](#testing)
- [Architecture Decisions](#architecture-decisions)
    - [ADR1.0](#adr10)


# Introduction and Goals

The purpose of this document is to provide a step-by-step guide for installing IBM Sterling File Gateway (and other B2Bi components) on Amazon EKS using Helm Charts. The solution aims to address the business need to host a cloud-ready data exchange platform using Sterling File Gateway and provide a scalable, secure and efficient file exchange solution.

This is a living document that is subject to change and evolution as IBM Client Engineering co-creates this solution with our customer.

# Solution Strategy
:construction:

## Overview
:construction:
## Building Block View
:construction:
## Deployment
### Pre-Requisites

#### Generic Requirements

- Amazon Web Services (AWS) account with necessary permissions
- Access to IBM B2Bi and Sterling File Gateway Enterprise Edition installation packages
- Basic knowledge of Helm, Kubernetes, and Amazon EKS
- Amazon EKS cluster up and running
- Helm CLI installed on the local machine
##### Trial sign-up for Sterling MFT

- Using your IBM ID, submit for SFG trial request using: <https://www.ibm.com/account/reg/us-en/signup?formid=urx-51433>
- Use the access token for IBM Entitled Registry from Step 1 to pull and stage images (in internal image repository, if necessary).


#### AWS Account
Configuring AWS Cli
#### AWS CLI Install

Download the client
```
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
```

Install it with sudo (to use for all users)
```
sudo installer -pkg ./AWSCLIV2.pkg -target /
```

Now let's configure our client env
```
aws configure
```

Answer all the questions with the info you got. If you already have a profile configured, you can add a named profile to your credentials

---
#### AWS EKS Cluster

The tool to use for managing EKS is called `eksctl`.

#### Installing or updating `eksctl`
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
- eksctl on Linux

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

-   Create a 3-node Kubernetes cluster named `mft-sterling-east` with one node type as `m5.xlarge` and region as `us-east-1`.
-   Define a node group named `standard-workers`.
-   Select a machine type for the `standard-workers` node group.
-   Specify our three AZs as `us-east-1a, us-east-1b, us-east-1c`
```
eksctl create cluster \
--name sterling-mft-east \
--version 1.23 \
--region us-east-1 \
--zones us-east-1a,us-east-1b,us-east-1c \
--nodegroup-name standard-workers \
--node-type m5.xlarge \
--nodes 3 \
--nodes-min 1 \
--nodes-max 4 \
--managed
```

Associate an IAM oidc provider with the cluster
```
eksctl utils associate-iam-oidc-provider \
--region=us-east-1 \
--cluster=sterling-mft-east \
--approve
```
Once the cluster is up, add it to your kube config
```
aws eks update-kubeconfig --name sterling-mft-east --region us-east-1
```

#### Granting Additional Access

If there are other users who need access to this cluster, you can grant them full access with the following commands:

Retrieve a list of user names and arns:

```
aws iam list-users --query 'Users[].[UserName, Arn]'

[
     [
        "user1",
        "arn:aws:iam::111111111111:user/user1"
    ],
    [
        "user2",
        "arn:aws:iam::111111111111:user/user2"
    ],
]
```

Add privileges with the Arn we've retrieved above. Bear in mind that this adds `system:master` access to the specified cluster

```
eksctl create iamidentitymapping \
--cluster sterling-mft-east \
--region=us-east-1 \
--arn arn:aws:iam::111111111111:user/user1 \
--group system:masters \
--no-duplicate-arns
```
This can also be applied to any AWS role

```
eksctl create iamidentitymapping \
--cluster sterling-mft-east \
--region=us-east-1 \
--arn arn:aws:iam::111111111111:role/Role1 \
--group system:masters \
--no-duplicate-arns
```
View the mappings in the cluster ConfigMap.
```
eksctl get iamidentitymapping --cluster sterling-mft-east --region=us-east-1
```
Do this for every user or role you want to grant access to.

Ref https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html

---

Create a namespace and set the context
```
kubectl create namespace sterling

kubectl config set-context --current --namespace=sterling
```

#### Elastic File Service (EFS) on EKS

By default when we create a cluster with eksctl it defines and installs `gp2` storage class which is backed by Amazon's EBS (elastic block storage). Being block storage, it's not super happy supporting RWX in our cluster. We need to install an EFS storage class.

#### Create an IAM policy and role

Create an IAM policy and assign it to an IAM role. The policy will allow the Amazon EFS driver to interact with your file system.

#### Deploy Amazon EFS CSI driver to an Amazon EKS cluster

Create an IAM policy that allows the CSI driver's service account to make calls to AWS APIs on your behalf. This will also allow it to create access points on the fly.

Download the IAM policy document from GitHub. You can also view the [policy document](https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/iam-policy-example.json)

```
curl -o iam-policy-efs.json https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json
```

Create the policy. You can change `AmazonEKS_EFS_CSI_Driver_Policy` to a different name, but if you do, make sure to change it in later steps too.
```
aws iam create-policy \
--policy-name AmazonEKS_EFS_CSI_Driver_Policy \
--policy-document file://iam-policy-efs.json

{
    "Policy": {
        "PolicyName": "AmazonEKS_EFS_CSI_Driver_Policy",
        "PolicyId": "ANPA24LVTCGN7YGDYRWJT",
        "Arn": "arn:aws:iam::748107796891:policy/AmazonEKS_EFS_CSI_Driver_Policy",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2023-01-24T17:24:00+00:00",
        "UpdateDate": "2023-01-24T17:24:00+00:00"
    }
}
```

Create an IAM role and attach the IAM policy to it. Annotate the Kubernetes service account with the IAM role ARN and the IAM role with the Kubernetes service account name. You can create the role using `eksctl` or the AWS CLI. We're gonna use `eksctl`, Also our `Arn` is returned in the output above, so we'll use it here.

```
eksctl create iamserviceaccount \
    --cluster sterling-mft-east \
    --namespace kube-system \
    --name efs-csi-controller-sa \
    --attach-policy-arn arn:aws:iam::748107796891:policy/AmazonEKS_EFS_CSI_Driver_Policy \
    --approve \
    --region us-east-1
```

Once created, check the iam service account is created running the following command.

```bash
eksctl get iamserviceaccount --cluster sterling-mft-east
NAMESPACE   NAME                    ROLE ARN
kube-system     efs-csi-controller-sa   arn:aws:iam::748107796891:role/eksctl-sterling-mft-east-addon-iamserviceacc-Role1-94PR0YDP0RF9
```

Now we just need our add-on registry address. This can be found here: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html

Let's install the driver add-on to our clusters. We're going to use `helm` for this.
```
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/

helm repo update

```

Install a release of the driver using the Helm chart. Replace the repository address with the cluster's [container image address](https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html).

```
helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
    --namespace kube-system \
    --set image.repository=602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-efs-csi-driver \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=efs-csi-controller-sa

```
Now we need to create the filesystem in EFS so we can use it

```
export clustername=sterling-mft-east
export region=us-east-1
```

```
vpc_id=$(aws eks describe-cluster \
    --name $clustername \
    --query "cluster.resourcesVpcConfig.vpcId" \
    --region $region \
    --output text)
```

Retrieve the CIDR range for your cluster's VPC and store it in a variable for use in a later step.

```
cidr_range=$(aws ec2 describe-vpcs \
    --vpc-ids $vpc_id \
    --query "Vpcs[].CidrBlock" \
    --output text \
    --region $region)
```

Create a security group with an inbound rule that allows inbound NFS traffic for your Amazon EFS mount points.

```
security_group_id=$(aws ec2 create-security-group \
    --group-name EFS4SecurityGroup \
    --description "EFS security group latest" \
    --vpc-id $vpc_id \
    --region $region \
    --output text)
```

Create an inbound rule that allows inbound NFS traffic from the CIDR for your cluster's VPC.

```
aws ec2 authorize-security-group-ingress \
    --group-id $security_group_id \
    --protocol tcp \
    --port 2049 \
    --region $region \
    --cidr $cidr_range
```

Create a file system.
```
file_system_id=$(aws efs create-file-system \
    --region $region \
    --encrypted \
    --performance-mode generalPurpose \
    --query 'FileSystemId' \
    --output text)
```
Create mount targets.

Determine the IDs of the subnets in your VPC and which Availability Zone the subnet is in.
```
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$vpc_id" \
    --query 'Subnets[*].{SubnetId: SubnetId,AvailabilityZone: AvailabilityZone,CidrBlock: CidrBlock}' \
    --region $region \
    --output table
```
Should output the following
```
----------------------------------------------------------------------
|                           DescribeSubnets                          |
+------------------+--------------------+----------------------------+
| AvailabilityZone |     CidrBlock      |         SubnetId           |
+------------------+--------------------+----------------------------+
|  us-east-1a      |  192.168.0.0/19    |  subnet-08ddff738c8fac2db  |
|  us-east-1b      |  192.168.32.0/19   |  subnet-0e11acfc0a427d52d  |
|  us-east-1b      |  192.168.128.0/19  |  subnet-0dd9067f0f828e49c  |
|  us-east-1c      |  192.168.160.0/19  |  subnet-0da98130d8b80f210  |
|  us-east-1a      |  192.168.96.0/19   |  subnet-02b159221adb9b790  |
|  us-east-1c      |  192.168.64.0/19   |  subnet-01987475cac20b583  |
+------------------+--------------------+----------------------------+
```
Add mount targets for the subnets that your nodes are in. Basically, for each SubnetId above, run the following command:

```
aws efs create-mount-target \
    --file-system-id $file_system_id \
    --region $region \
    --subnet-id <SUBNETID> \
    --security-groups $security_group_id
```
Create a storage class for dynamic provisioning

Let's get our filesystem ID if we don't already have it above.
```
aws efs describe-file-systems \
--query "FileSystems[*].FileSystemId" \
--region $region \
--output text

fs-071439ffb7e10b67b
```

Update it with the storage class id
```
sed -i 's/fileSystemId:.*/fileSystemId: fs-071439ffb7e10b67b/' EFSStorageClass.yaml
```

Download a `StorageClass` manifest for Amazon EFS.
```
curl -o EFSStorageClass.yaml https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/examples/kubernetes/dynamic_provisioning/specs/storageclass.yaml
```
Also make sure your storageclass looks like this:
```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
mountOptions:
  - tls
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-071439ffb7e10b67b
  directoryPerms: "775"
  gidRangeStart: "1000" # optional
  gidRangeEnd: "3000" # optional
  basePath: "/efs/dynamic_provisioning" # optional
  uid: "2001" # This tells the provisioner to make the owner this uid
  gid: "65534" # This tells the provisioner to make the group owner this gid
```

Deploy the storage class.

```
kubectl apply -f EFSStorageClass.yaml
```

Finally, verify it's there
```
kubectl get sc
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
efs-sc          efs.csi.aws.com         Delete          Immediate              false                  7s
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  13d
```

#### Add Security Policies

The following sample file illustrates RBAC for the default service account with the target namespace as `sterling`

Create a file called `sterling-rbac.yaml`

```
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ibm-b2bi-role-sterling
  namespace: sterling
rules:
  - apiGroups: ['','batch']
    resources: ['secrets','configmaps','persistentvolumeclaims','pods','services','cronjobs','jobs']
    verbs: ['create', 'get', 'list', 'delete', 'patch', 'update']

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ibm-b2bi-rolebinding-sterling
  namespace: sterling
subjects:
  - kind: ServiceAccount
    name: default
    namespace: sterling
roleRef:
  kind: Role
  name: ibm-b2bi-role-sterling
  apiGroup: rbac.authorization.k8s.io
```

Apply it to the cluster
```
kubectl apply -f sterling-rbac.yaml
```
#### Security Policies

With Kubernetes v1.25, Pod Security Policy (PSP) API has been removed and replaced with Pod Security Admission (PSA) contoller. Kubernetes PSA conroller enforces predefined Pod Security levels at the namespace level. The Kubernetes Pod Security Standards defines three different levels: privileged, baseline, and restricted. Refer to Kubernetes [`Pod Security Standards`] ([https://kubernetes.io/docs/concepts/security/pod-security-standards/](https://kubernetes.io/docs/concepts/security/pod-security-standards/)) documentation for more details. This chart is compatible with the restricted security level.

The version of kubernetes in EKS in our instance is 1.23. So the following policies would be applied. Below is an optional custom PSP definition based on the IBM restricted PSP.

Predefined PodSecurityPolicy name: [`ibm-restricted-psp`](https://ibm.biz/cpkspec-psp)

From the user interface or command line, you can copy and paste the following snippets to create and enable the below custom PodSecurityPolicy based on IBM restricted PSP.

`custom-podsecpolicy.yaml`
```
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: "ibm-b2bi-psp"
  labels:
    app: "ibm-b2bi-psp"

spec:
  privileged: false
  allowPrivilegeEscalation: false
  hostPID: false
  hostIPC: false
  hostNetwork: false
  allowedCapabilities:
  requiredDropCapabilities:
  - MKNOD
  - AUDIT_WRITE
  - KILL
  - NET_BIND_SERVICE
  - NET_RAW
  - FOWNER
  - FSETID
  - SYS_CHROOT
  - SETFCAP
  - SETPCAP
  - CHOWN
  - SETGID
  - SETUID
  - DAC_OVERRIDE
  allowedHostPaths:
  runAsUser:
    rule: MustRunAsNonRoot
  runAsGroup:
    rule: MustRunAs
    ranges:
    - min: 1
      max: 4294967294
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: MustRunAs
    ranges:
    - min: 1
      max: 4294967294
  fsGroup:
    rule: MustRunAs
    ranges:
    - min: 1
      max: 4294967294
  volumes:
  - configMap
  - emptyDir
  - projected
  - secret
  - downwardAPI
  - persistentVolumeClaim
  - nfs
  forbiddenSysctls:
  - '*'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: "ibm-b2bi-psp"
  labels:
    app: "ibm-b2bi-psp"
rules:
- apiGroups:
  - policy
  resourceNames:
  - "ibm-b2bi-psp"
  resources:
  - podsecuritypolicies
  verbs:
  - use
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: "ibm-b2bi-psp"
  labels:
    app: "ibm-b2bi-psp"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: "ibm-b2bi-psp"
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:serviceaccounts
  namespace: sterling
```

Apply it to the cluster
```
kubectl apply -f custom-podsecpolicy.yaml
```
---
#### Helm Chart installation

```
helm repo add ibm-helm https://raw.githubusercontent.com/IBM/charts/master/repo/ibm-helm

helm repo add mq-helm-eks https://ibm-client-engineering.github.io/mq-helm-eks/
```


> # Info
>Charts: <https://github.com/IBM/charts/blob/master/repo/ibm-helm/ibm-sfg-prod.md>
 <https://github.com/IBM/charts/blob/master/repo/ibm-helm/ibm-sfg-prod-2.1.1.tgz>

---

### Configure IBM MQ on the cluster

Create a new namespace for MQ
```
kubectl create namespace mqsterling
```

Set our context to it

```
kubectl config set-context --current --namespace=mqsterling
```

Create a values file called `sterling_values.yaml`
```
# © Copyright IBM Corporation 2021, 2022
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

license: accept
log:
  debug: false

image:
  # repository is the container repository to use
  # repository: <URL FOR AIRGAPPED REPO>/icr.io/ibm-messaging/mq
  # This should point to either the IBM repo by default or it can be changed to point elsewhere.
  repository: icr.io/ibm-messaging/mq
  # tag is the tag to use for the container repository
  tag: latest
  # pullSecret is the secret to use when pulling the image from a private registry
  # pullSecret: ics-cots-pullsecret
  pullSecret:
  # pullPolicy is either IfNotPresent or Always (https://kubernetes.io/docs/concepts/containers/images/)
  pullPolicy: IfNotPresent

queueManager:
  name: b2bi
  nativeha:
    enable: false
  multiinstance:
    enable: true

metrics:
  enabled: true

persistence:
  dataPVC:
    enable: true
    name: "data"
    size: 2Gi
    storageClassName: "efs-sc"
  logPVC:
    enable: true
    name: "log"
    size: 2Gi
    storageClassName: "efs-sc"
  qmPVC:
    enable: true
    name: "qm"
    size: 2Gi
    storageClassName: "efs-sc"

security:
  context:
    fsGroup: 65534
#    fsGroup: 0
    supplementalGroups: [65534,2001]
  initVolumeAsRoot: false
  runAsUser: 2001
  runAsGroup: 2001

metadata:
  annotations:
    productName: "IBM MQ Advanced for Developers"
    productID: "2f886a3eefbe4ccb89b2adb97c78b9cb"
    productChargedContainers: ""
    productMetric: "FREE"
route:
  nodePort:
    webconsole: true
    mqtraffic: true
  loadBalancer:
    webconsole: false
    mqtraffic: true
  ingress:
    webconsole:
      enable: true
      hostname:
      path: /ibmmq
      tls:
        enable: false
    mqtraffic:
      enable: false
      hostname:
      path:
      tls:
        enable: false
```
Install IBM MQ with the following command

```
helm install sterlingmq mq-helm-eks/ibm-mq -f sterling_values.yaml \
--set "queueManager.envVariables[0].name=MQ_ADMIN_PASSWORD" \
--set "queueManager.envVariables[0].value=mqpasswd" \
--set "queueManager.envVariables[1].name=MQ_APP_PASSWORD" \
--set "queueManager.envVariables[1].value=mqpasswd"
```

The command above will create a loadbalancer with port 1414 as the access port for the queue manager and will create an ingress for the web console provided you've installed NGINX ingress capability into the cluster.

---

#### RDS/DB Schema

Create a security group. We're going to get our vpc for our sterling cluster first and use that here since we don't have any default vpc.

Let's export the following env vars
```
export clustername=sterling-mft-east
export region=us-east-1
```

Now let's retrieve our vpc id
```
vpc_id=$(aws eks describe-cluster \
    --name $clustername \
    --query "cluster.resourcesVpcConfig.vpcId" \
    --region $region \
    --output text)
```
And with those vars set, let's now create our security group
```
security_group_id=$(aws ec2 create-security-group \
    --group-name RDSSterlingSecGroup \
    --description "RDS Access to Sterling Cluster" \
    --vpc-id $vpc_id \
    --region $region \
    --output text)
```
Retrieve the CIDR range for your cluster's VPC and store it in a variable for use in a later step.

```
cidr_range=$(aws ec2 describe-vpcs \
    --vpc-ids $vpc_id \
    --query "Vpcs[].CidrBlock" \
    --output text \
    --region $region)
```

Let's authorize access to that group for Oracle which uses port 1521

```
aws ec2 authorize-security-group-ingress \
    --group-id $security_group_id \
    --protocol tcp \
    --port 1521 \
    --region $region \
    --cidr $cidr_range
```

Let's create a db subnet group. First get our existing subnet ids from our vpc

```
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$vpc_id" \
    --query 'Subnets[*].{SubnetId: SubnetId,AvailabilityZone: AvailabilityZone,CidrBlock: CidrBlock}' \
    --region $region \
    --output table
```

```
----------------------------------------------------------------------
|                           DescribeSubnets                          |
+------------------+--------------------+----------------------------+
| AvailabilityZone |     CidrBlock      |         SubnetId           |
+------------------+--------------------+----------------------------+
|  us-east-1a      |  192.168.0.0/19    |  subnet-08ddff738c8fac2db  |
|  us-east-1b      |  192.168.32.0/19   |  subnet-0e11acfc0a427d52d  |
|  us-east-1b      |  192.168.128.0/19  |  subnet-0dd9067f0f828e49c  |
|  us-east-1c      |  192.168.160.0/19  |  subnet-0da98130d8b80f210  |
|  us-east-1a      |  192.168.96.0/19   |  subnet-02b159221adb9b790  |
|  us-east-1c      |  192.168.64.0/19   |  subnet-01987475cac20b583  |
+------------------+--------------------+----------------------------+
```

Now let's create our db subnet group

```
aws rds create-db-subnet-group \
--db-subnet-group-name "sterling-rds-subnet-group" \
--db-subnet-group-description "This is our cluster subnet ids authorized and grouped for RDS" \
--subnet-ids "subnet-08ddff738c8fac2db" "subnet-0e11acfc0a427d52d" "subnet-0dd9067f0f828e49c" "subnet-0da98130d8b80f210" "subnet-02b159221adb9b790" "subnet-01987475cac20b583"
```


Now with all those prerequisites completed, let's create the RDS instance:

```
aws rds create-db-instance \
    --engine oracle-ee \
    --db-instance-identifier sterling-mft-db \
    --allocated-storage 300 \
    --multi-az \
    --db-subnet-group-name sterling-rds-subnet-group \
    --db-instance-class db.t3.large \
    --vpc-security-group-ids $security_group_id \
    --master-username oracleuser \
    --master-user-password oraclepass \
    --backup-retention-period 3
```


---
#### Images and Internal Registry
We are going to set up an Amazon Elastic Container Registry. For this we will first create a repository

```
aws ecr create-repository \
--repository-name sterling-mft-repo \
--region us-east-1 \
--encryption-configuration encryptionType=AES256
```
Pay attention to the output of the above command. It will look similar to this:
```
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:748107796891:repository/sterling-mft-repo",
        "registryId": "748107796891",
        "repositoryName": "sterling-mft-repo",
        "repositoryUri": "748107796891.dkr.ecr.us-east-1.amazonaws.com/sterling-mft-repo",
        "createdAt": "2023-02-03T15:45:52-05:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
}
```
Make a note of the `repositoryUri`.

We can retrieve the login password token with the following command. This retrieves and exports the token as an env var called `login_passwd`.
```
login_passwd=$(aws ecr get-login-password --region us-east-1)
```
Now we need to create a secret in the cluster to map the token. We need the `repositoryUri` from above for `--docker-server`
```
kubectl create secret docker-registry sterling-secret \
--docker-server="https://748107796891.dkr.ecr.us-east-1.amazonaws.com/sterling-mft-repo" \
--docker-username=AWS \
--docker-password=$login_passwd \
--docker-email="YOUR_EMAIL"
```

#### **Install NGINX Ingress**

Create an IAM policy.

Download an IAM policy for the AWS Load Balancer Controller that allows it to make calls to AWS APIs on your behalf.

```
curl -o iam_loadbalancer_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json
```

Create an IAM policy using the policy downloaded in the previous step.
```
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

{
    "Policy": {
        "PolicyName": "AWSLoadBalancerControllerIAMPolicy",
        "PolicyId": "ANPA24LVTCGNV55JFAAP5",
        "Arn": "arn:aws:iam::748107796891:policy/AWSLoadBalancerControllerIAMPolicy",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2023-01-17T20:22:23+00:00",
        "UpdateDate": "2023-01-17T20:22:23+00:00"
    }
}
```
Create an IAM role. Take note of the returned `arn` above and use it to create a Kubernetes service account named `aws-load-balancer-controller` in the `kube-system` namespace for the AWS Load Balancer Controller and annotate the Kubernetes service account with the name of the IAM role.

Important to note that if you have multiple clusters in the same region, the `--name` and `--role-name` must be unique.

```
eksctl create iamserviceaccount \
  --cluster=sterling-mft-east \
  --namespace=kube-system \
  --name=aws-load-balancer-controller-mft \
  --role-name AmazonEKSLoadBalancerControllerRoleMft \
  --attach-policy-arn=arn:aws:iam::748107796891:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```

Install the EKS helm repo
```
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

Install the AWS Load Balancer Controller.
```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=sterling-mft-east \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller-mft

```

```
kubectl get deployment -n kube-system aws-load-balancer-controller
```

Pull down the NGINX controller deployment
```
curl -o nginx-deploy.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml
```

Modify the deployment file and add the following annotations under the Service `ingress-nginx-controller`
```
service.beta.kubernetes.io/aws-load-balancer-type: "external"
service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
```

Apply the deployment
```
kubectl apply -f nginx-deploy.yaml
```



---

### Installation
:construction:

## Security
:construction:
## Testing
:construction:
# Architecture Decisions
### ADR1.0
- Images will be staged to an internal Image registry.
