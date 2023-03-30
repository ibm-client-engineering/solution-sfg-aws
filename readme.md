<h1>IBM Client Engineering - Solution Document</h1>

<h2>IBM Sterling: Cloud Ready Data Exchange</h2>
<a href="https://www.ibm.com/client-engineering"><img align="right" src="https://user-images.githubusercontent.com/95059/166857681-99c92cdc-fa62-4141-b903-969bd6ec1a41.png" width="491" ></a>

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
      - [Install NGINX Ingress and AWS Loadbalancer](#install-nginx-ingress)
      - [Add Security Policies](#add-security-policies)
      - [Security Policies](#security-policies)
      - [Helm Chart installation](#helm-chart-installation)
      - [RDS/DB Schema](#rdsdb-schema)
      - [**Configure Oracle RDS Instance**](#configure-oracle-rds-instance)
      - [Images and Internal Registry](#images-and-internal-registry)
    - [Installation](#installation)
      - [Secrets](#secrets)
      - [Sidecar Deployment](#sidecar-deployment)
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

Configure two separate EFS storage classes, one for Sterling and one for MQ. The reason for this is MQ requires specific userids to work happily when using shared storage whereas Sterling requires its own user to own stuff and might cause conflicts. By specifying separate classes we eliminate the problem. Make sure the `fileSystemId` is the same for both.

`EFSStorageClass.yaml`
```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-mq-sc
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
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sfg-sc
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
  uid: "1010" # This tells the provisioner to make the owner this uid
  gid: "1010" # This tells the provisioner to make the group owner this gid
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

---
#### Helm Chart installation

```
helm repo add ibm-helm https://raw.githubusercontent.com/IBM/charts/master/repo/ibm-helm

helm repo add ibm-messaging-mq https://ibm-messaging.github.io/mq-helm
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
    storageClassName: "efs-mq-sc"
  logPVC:
    enable: true
    name: "log"
    size: 2Gi
    storageClassName: "efs-mq-sc"
  qmPVC:
    enable: true
    name: "qm"
    size: 2Gi
    storageClassName: "efs-mq-sc"

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
```
Install IBM MQ with the following command

```
helm install sterlingmq ibm-messaging-mq/ibm-mq \
-f sterling_values.yaml \
--set "queueManager.envVariables[0].name=MQ_ADMIN_PASSWORD" \
--set "queueManager.envVariables[0].value=mqpasswd" \
--set "queueManager.envVariables[1].name=MQ_APP_PASSWORD" \
--set "queueManager.envVariables[1].value=mqpasswd"
```

The command above will create a loadbalancer with port 1414 as the access port for the queue manager and will create an ingress for the web console provided you've installed NGINX ingress capability into the cluster.

Create the MQ Secret 

`mqsecret.yaml`
```
apiVersion: v1
kind: Secret
metadata:
    name: mq-secret
type: Opaque
stringData:
    JMS_USERNAME: mqadmin
    JMS_PASSWORD: mqpasswd
# Set these values if we have setup our keystores for MQ
#  JMS_KEYSTORE_PASSWORD: 
#  JMS_TRUSTSTORE_PASSWORD: 
#    
```

apply the secret to the sterling namespace

```
kubectl apply -f mqsecret.yaml -n sterling
```

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

A default DB called `ORCL` will be created

---

#### **Configure Oracle RDS Instance**

Configure a pod in the `sterling` in your namespace using the below yaml:

`oracle_client.yaml`
```
apiVersion: v1
kind: Pod
metadata:
  name: oracleclient
  labels:
    app: oracleclient
spec:
  containers:
    - name: instantclient
      image: ghcr.io/oracle/oraclelinux8-instantclient:19
      command: ["sleep"]
      args: ["infinity"]
```

Create the pod
```
kubectl apply -f oracle_client.yaml
```
Verify the pod is up and running

```
kubectl get pods
NAME           READY   STATUS    RESTARTS   AGE
oracleclient   1/1     Running   0          22m
```

Connect to your db instance. The user is `oracleuser` and the password is `oraclepass` as we set when we created the RDS instance. The port will be `1521`. We will retrieve the endpoint with the `aws` cli and export it as a var called `$endpoint`.

```
endpoint=$(aws rds describe-db-instances --query "DBInstances[*].Endpoint.Address" --output text)

kubectl exec -it oracleclient -- sqlplus "oracleuser/oraclepass@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$endpoint)(PORT=1521))(CONNECT_DATA=(SID=ORCL)))"

SQL*Plus: Release 19.0.0.0.0 - Production on Wed Feb 15 17:16:05 2023
Version 19.18.0.0.0

Copyright (c) 1982, 2022, Oracle.  All rights reserved.

Last Successful login time: Wed Feb 15 2023 17:07:24 +00:00

Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.17.0.0.0

SQL>

```

Now that we have an Oracle RDS instance and we are logged in, we are going to configure the database in preparation for Sterling B2Bi installation.

Run the following SQL script that will do the following:

1. Create a tablespace for user tables and indexes
2. Set newly created tablespace as default
3. Create a new user for Sterling. This is the user we will be using for the database.
4. Grant permissions to the Sterling user

Copy and paste the following into the SQL cmdline prompt.
```
/*
Create tablespace
*/
CREATE TABLESPACE SI_USERS DATAFILE SIZE 1G AUTOEXTEND ON MAXSIZE 100G;

/*
Set new tablespace as default
*/
EXEC rdsadmin.rdsadmin_util.alter_default_tablespace(tablespace_name => 'SI_USERS');

/*
Create new user for Sterling
*/
CREATE USER SI_USER IDENTIFIED BY dbpassword;

/*
Grant necessary permissions to newly created Sterling user
*/
GRANT "CONNECT" TO SI_USER;
ALTER USER SI_USER DEFAULT ROLE "CONNECT";
ALTER USER SI_USER QUOTA 100G ON SI_USERS;
GRANT CREATE SEQUENCE TO SI_USER;
GRANT CREATE TABLE TO SI_USER;
GRANT CREATE TRIGGER TO SI_USER;
GRANT SELECT ON CTXSYS.CTX_USER_INDEXES TO SI_USER;
GRANT SELECT ON SYS.DBA_DATA_FILES TO SI_USER;
GRANT SELECT ON SYS.DBA_FREE_SPACE TO SI_USER;
GRANT SELECT ON SYS.DBA_USERS TO SI_USER;
GRANT SELECT ON SYS.V_$PARAMETER TO SI_USER;
GRANT SELECT ANY DICTIONARY TO SI_USER;
GRANT ALTER SESSION TO SI_USER;
GRANT CREATE SESSION TO SI_USER;
GRANT CREATE VIEW TO SI_USER;

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

If we are just using the IBM repository, create a docker pull secret for it using your IBM pull secret that can be retrieved from here:

https://myibm.ibm.com/products-services/containerlibrary

```
export ibm_pull_secret="MY PULL SECRET"

kubectl create secret docker-registry ibm-pull-secret \
--docker-server="cp.icr.io" \
--docker-username=cp \
--docker-password=$ibm_pull_secret \
--docker-email="YOUR_EMAIL"
```

Patch your default service account for the namespace

```
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "ibm-pull-secret"}]}'
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
#### Install the AWS Load Balancer Controller.

Install the EKS helm repo
```
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```
Now install the loadbalancer controller
```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=sterling-mft-east \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller-mft

```
Verify the deployment
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
Final entry should look like this:
```
apiVersion: v1
kind: Service
metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.6.4
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  externalTrafficPolicy: Local
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - appProtocol: http
    name: http
    port: 80
    protocol: TCP
    targetPort: http
  - appProtocol: https
    name: https
    port: 443
    protocol: TCP
    targetPort: https
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
  type: LoadBalancer
```
Apply the deployment
```
kubectl apply -f nginx-deploy.yaml
```




---

### Installation

#### Secrets

Create the following secrets in the `sterling` namespace

`sterling-secrets.yaml`
```
apiVersion: v1
kind: Secret
metadata:
  name: b2b-system-passphrase-secret
type: Opaque
stringData:
  SYSTEM_PASSPHRASE: password
---
apiVersion: v1
kind: Secret
metadata:
    name: mq-secret
type: Opaque
stringData:
    JMS_USERNAME: app
    JMS_PASSWORD: mqpasswd
---
apiVersion: v1
kind: Secret
metadata:
  name: b2b-db-secret
type: Opaque
stringData:
  DB_USER: SI_USER
  DB_PASSWORD: dbpassword
```
As a note, we are setting the user/pass for the database to `SI_USER` with a password of `dbpassword`.

Apply the secrets.
```
kubectl apply -f sterling-secrets.yaml -n sterling
```

#### Sidecar deployment

Create a sidecar pod and storage volume to stage the files required to deploy.

`sterlingtoolkitdeploy.yaml`
```
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sterlingtoolkit-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sfg-sc
  resources:
    requests:
      storage: 20Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sterlingtoolkit
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sterlingtoolkit
  template:
    metadata:
      labels:
        app: sterlingtoolkit
    spec:
      containers:
      - name: sterlingtoolkit
        image: centos
        command: ["/bin/sh"]
        args: ["-c", "useradd -u 1010 b2biuser && sleep infinity"]
        volumeMounts:
        - mountPath: /var/nfs-data/resources
          name: storagevol
      volumes:
      - name: storagevol
        persistentVolumeClaim:
          claimName: sterlingtoolkit-pvc
```

Create the sidecar pod and volume
```
kubectl apply -f sterlingtoolkitdeploy.yaml
```

Download the Oracle JDBC driver

https://download.oracle.com/otn-pub/otn_software/jdbc/219/ojdbc8.jar

Determine our pod name
```
kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
oracleclient                       1/1     Running   0          3h55m
sterlingtoolkit-577b8c56f5-dchdx   1/1     Running   0          4m59s
```

Upload the jar file to the appropriate folder

```
kubectl cp ojdbc11.jar sterlingtoolkit-577b8c56f5-dchdx:/var/nfs-data/resources
```
#### Download the Sterling helm charts

The following links are for the required helm charts for this installation

[ibm-sfg-prod-2.1.1](https://github.com/IBM/charts/raw/master/repo/ibm-helm/ibm-sfg-prod-2.1.1.tgz)

[ibm-b2bi-prod-2.1.1](https://github.com/IBM/charts/raw/master/repo/ibm-helm/ibm-b2bi-prod-2.1.1.tgz)

Download the `ibm-b2bi-prod` helm charts from the above link.

Extract the `ibm-b2bi-prod-2.1.1.tgz` file
```
tar zxvf ibm-b2bi-prod-2.1.1.tgz
```
We will need to update the Kubernetes version in the `Chart.yaml`

```
cd ibm-b2bi-prod
```

Retrieve our EKS kubernetes version
```
kubectl version --short

Client Version: v1.23.0
Kustomize Version: v4.5.7
Server Version: v1.23.14-eks-ffeb93d
```
Make a note of the `Server Version` and edit the `Chart.yaml` file in the `ibm-b2bi-prod` directory. Update the following:

```
kubeVersion: '>=v1.21'
```
should be changed to our Server Version
```
kubeVersion: '>=v1.23.14-eks-ffeb93d'
```

Create a sterling override file similar to these.

This is valid for installing the Sterling B2BI product. 

[sterling-overrides-b2bi.yaml](overrides/sterling-b2bi-values.yaml)

If using Sterling SFG

[sterling-overrides-sfg.yaml](overrides/sterling-sfg-values.yaml)

If you need to add custom labeling for the pods, look for this section under each application definition in the overrides file:

```
  # for pod Affinity and podAntiAffinity
  extraLabels: {}
    #acLabel: acValue
```

Add the labels that would be applied to each pod

```
  # for pod Affinity and podAntiAffinity
  extraLabels:
    customlabelname: customlabelvalue 
```

Host entries for each ingress should match what your existing domain is if you don't have a dedicated FQDN. This means you should set a wildcard.

In our example, we are on AWS so our ingress host entries look like the following in the overrides document:

```
  ingress:
    internal:
      host: "*.elb.us-east-1.amazonaws.com"
      tls:
        enabled: true
        secretName: sterling-b2bi-b2bi-ac-frontend-svc
      extraPaths: []
    external:
      host: "*.elb.us-east-1.amazonaws.com" 
      tls:
        enabled: true
        secretName: sterling-b2bi-b2bi-ac-frontend-svc
      extraPaths: []
```

#### TLS SecretNames for ingress

When the tls option is enabled for each app container, the secretName is created by the creattls job that is run at the beginning of the installation. So that secret can be applied in advance to the overrides:

```
ac.ingress.external.tls.enabled = true

ac.ingress.external.tls.secretName = sterling-b2bi-b2bi-ac-frontend-svc

asi.ingress.external.tls.enabled = true

asi.ingress.external.tls.secretName = sterling-b2bi-b2bi-asi-frontend-svc

api.ingress.external.tls.enabled = true

api.ingress.external.tls.secretName = sterling-b2bi-b2bi-asi-frontend-svc
```

Run the helm installation with the following command

```
helm install sterling-b2bi -f sterling-b2bi-values.yaml /path/to/ibm-b2bi-prod --timeout 3600s --namespace sterling
```

Installation should take approximately 40 minutes

### Sterling Users:

| Role | User ID | Password |
|------|---------|----------|
| System Administrator | fg_sysadmin | password |
| Integration Architect | fg_architect | password |
| Route Provisioner |	fg_provisioner | password |
| Operator | fg_operator | password |

### Application Validation

Relevant URL:
https://www.ibm.com/docs/en/b2b-integrator/6.1.2?topic=overview-sterling-file-gateway-tutorial

#### Configuring communication adapters:

The following adapters can be used with Sterling File Gateway:

| Protocol | Adapter | 
|----------|---------|
| FTP, FTPS | FTP Server adapter |
| FTP, FTPS |	FTP Client adapter and services |
| SSH/SFTP, SSH/SCP |	SFTP Server adapter |
| SSH/SFTP |	SFTP Client adapter and services |
| Sterling Connect:Direct |	Connect:Direct Server adapter |
| PGP |	Command Line Adapter 2 |
| HTTP, HTTPS, WebDAV (Requires extensibility. See Add Custom Protocols.) |	HTTP Server adapter |
| HTTP, HTTPS, WebDAV (Requires extensibility. See Add Custom Protocols.) |	HTTP Client adapter and services |
| WebSphere® MQ File Transfer Edition |	WebSphere MQ File Transfer Edition Agent adapter<br> WebSphere MQ Suite Async adapter<br> WebSphere MQ File Transfer Edition Create Transfer service <br> FTP Server Adapter |


Primary URL can be found with the following command:
```
kubectl get ingress sterling-b2bi-b2bi-ingress -o jsonpath="{..hostname}"

k8s-ingressn-ingressn-f9d3dcbc72-69d548b3e1e33f06.elb.us-east-1.amazonaws.com
```
Login to the dashboard as `fg_sysadmin`:

https://k8s-ingressn-ingressn-f9d3dcbc72-69d548b3e1e33f06.elb.us-east-1.amazonaws.com/dashboard

From the main menu: 
1. Select Deployment > Services > Configuration.
2. Select and configure the adapters you require.

As an example, let's configure SFTP. Per the above table, SFTP is `SFTP Client adapter`

Log out of dashboard and log back into the `filegateway` as `fg_architect`:

https://k8s-ingressn-ingressn-f9d3dcbc72-69d548b3e1e33f06.elb.us-east-1.amazonaws.com/filegateway

From the main menu, select **Participants > Communities** to create a community with the following values:

| Field | Value |
|-------|-------|
|Community Name |	FirstComm |
|Partner Initiates Protocol Connection|	X |
|Partner Listens for Protocol Connections |X |
|SSH/SFTP | X |
|Should Receive Notification|	Yes |

Select **Participants > Groups** to create a group named `Group1`.

Log out of `filegateway` and log back in as `fg_provisioner`

Create two partners with the following values:
Select **Participants > Partners** 

|Field| Value For First Partner| Value For Second Partner|
|-----|------|-----|
|Community|FirstComm|FirstComm|
|Partner Name|Partner1|Partner2|
|Phone|333|444|
|Email|y@x.com|x@y.com|
|User Name|partner1|partner2|
|Password|p@ssw0rd|p@ssw@rd|
|Given Name|partner|partner|
|Surname|1|2|
|Partner Role| Is a consumer of data<br> - Initiates a connection|Is a producer of data|
|Use SSH|Yes|Yes|
|Use Authorized User Key|No|No|
|PGP Settings|- No<br>- No|- No<br> - No|

Associate the partners with Group1. Select Participants > Groups > Add Partner. Select the partners and the group, and click Execute

Log out and log back into the `filegateway` as `fg_architect`

Select Routes > Templates > Create to create a routing channel template with the following values:

| | |
|---|---|
|<img src="images/Template_Type.png" alt= “Type” width="300">|<img src="images/Template_Special_Characters.png" alt= “Type” width="300">|
|<img src="images/Template_Groups.png" alt= “Groups” width="300">|<img src="images/Template_Provisioning_Facts.png" alt=“Facts” width="300">|
|<img src="images/Template_Producer_File_Structure.png" alt=“ProducerFileStructure” width="300">|<img src="images/Template_Consumer_File_Structure_add.png" alt=“Type” width="300">|
|<img src="images/Template_Consumer_File_Structure_format.png" alt=“Type” width="300">|<img src="images/Template_Consumer_File_Structure_Save.png" alt=“Type” width="300">
<image>

Save the template

Log out and log back into `filegateway` as `fg_provisioner`

Create a routing channel with the following values:

|Field|Value|
|-----|-----|
|Routing Channel Template|FirstStatic|
|Producer|Partner2|
|Consumer|Partner1|
|User ID|User1|

Log out of the UI and log in to the `myFileGateway` ui as `partner2`. You will probably need to change the password on first login.

https://k8s-ingressn-ingressn-f9d3dcbc72-69d548b3e1e33f06.elb.us-east-1.amazonaws.com/myfilegateway

Upload a text file to the `/` mailbox and then log out.

Log in to `myfilegateway` as `partner1`. You will probably need to change the password on first login.

Click the `Download File` tab and see if the file is there. Since Partner1 is the consumer and Partner2 is the sender, the file should show up there.

Click on the file and download. Verify the file is downloaded and matches the naming convention we set.

Log out and log back in to `filegateway` as `fg_operator`. If the default `password` password does not work for him, you might need to log back into the dashboard as `fg_sysadmin` and manually set `fg_operator`'s password. Then you will be required to change it when you log in to the `filegateway`

Search for the file that was uploaded. We called it `readme.txt` in this example.

<img src="images/File_Search.png" alt=“FileSearch” width="300">

<img src="images/File_Search2.png" alt="FileStats" width="300">


## Security
:construction:
## Testing
:construction:
# Architecture Decisions
### ADR1.0
- Images will be staged to an internal Image registry.
