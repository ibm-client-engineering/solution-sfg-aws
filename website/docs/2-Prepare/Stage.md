---
id: stage
sidebar_position: 3
title: Stage
---
# Stage

## Software

- Generic Requirements:

    - Amazon Web Services (AWS) account with necessary permissions
    - Access to IBM B2Bi and Sterling File Gateway Enterprise Edition installation packages
    - Basic knowledge of Helm, Kubernetes, and Amazon EKS
    - Amazon EKS cluster up and running
    - Helm CLI installed on the local machine


- Hardware
  - EKS
    - `m5.xlarge` and region as `us-east-1`. (this has 4 vcpu and 16 gigs ram)
    - Default storage class defined
  - Jump Server/Bastion Host for staging requirements

## Helm Chart installations 

Install the following two helm repos as they will be required:

```
helm repo add ibm-helm https://raw.githubusercontent.com/IBM/charts/master/repo/ibm-helm

helm repo add ibm-messaging-mq https://ibm-messaging.github.io/mq-helm
```
:::info

Download the latest Sterling helm charts for B2Bi from this link. (Currently 2.1.3 as of this writing)

Charts: <https://github.com/IBM/charts/blob/master/repo/ibm-helm/ibm-sfg-prod.md>

[ibm-b2bi-prod-2.1.3](https://github.com/IBM/charts/blob/master/repo/ibm-helm/ibm-b2bi-prod-2.1.3.tgz)

:::

## AWS Account

In this section we will setup up you setup your AWS command line and credentials.

You can run a curl command to install the AWS CLI or you can go to https://awscli.amazonaws.com/AWSCLIV2.pkg and setup the AWS CLI using GUI installer. We will be using Mac OS in this documentation, but you can find specific instruction for you OS here: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html. The following steps will demonstrate how to setup the AWS CLI through the Mac CLI. 

Download the AWS CLI Client using curl. We can use the -o flag to set the output file name. In this case we set it to "AWSCLIV2.pkg"

```
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
```

Next, we need to install the file we just got from the curl command. We can run the following command to install. Install it with sudo (to use for all users). The installer command is command-line tool on macOS used to install software packages. The -pkg flag specifies the package file to be installed. In this case, the package file is "AWSCLIV2.pkg," which should be located in the current directory ("./"). Last the -target option specifies the destination location for the installation. In this case, the forward slash ("/") indicates that the installation should be performed in the root directory of the macOS system.

```
sudo installer -pkg ./AWSCLIV2.pkg -target /
```

Now that the AWS CLI is installed, let's configure our client. We can do that by running the following command. 

```
aws configure
```

The command will prompt you for your AWS Access Key ID, AWS Secret Access Key, Default Region, and Default Format. If you are unsure what your Access Key and Key ID are, you can generate new keys from the AWS console. Within the console, go to Identity and Access Management (IAM). Within the IAM dashboard, there should be a section called "Manage Access Keys". Here you can create and manage your AWS access keys. If you generate a new ID and Key, remember the Key will only be displayed once. Make sure to take note of it before proceeding with the key creation.  If you already have a profile configured, you can add a named profile to your credentials

If you need to edit you profile, you can use an editor and make changes. With AWS CLI, your configurations are in two files: ~/.aws/credentials and ~/.aws/config. 

Lastly, we are not limited to one profile. We can have multiple users, keys, and configurations (if needed). The following shows our configuration files with two profiles. 

```tsx
vi ~/.aws/credentials

[default]
aws_access_key_id =
aws_secret_access_key =

[<ACCOUNTID>_AWSAdmin]
aws_access_key_id=
aws_secret_access_key=
```

Also add location info to the config file

```tsx
vi ~/.aws/config

[default]
region = us-east-1
output = json

[profile techzone_user]
region=us-east-1
output=json
```

Now that we have our AWS CLI configured, we can select which profile to use by using the following command. 

```
export AWS_PROFILE=<ACCOUNTID>_AWSAdmin
```

You may also copy the following out of the aws portal and paste it into your shell

```
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
```

## AWS VPC and EKS Cluster

### Installing or updating `eksctl`


The `eksctl` command is a command-line tool used to create, manage, and operate Amazon Elastic Kubernetes Service (Amazon EKS) clusters. It simplifies the process of creating and managing Kubernetes clusters on AWS. 

We can install this tool using homebrew on MacOS. Homebrew, also known as Brew, is a package manager for macOS. It allows you to easily install, manage, and update various software packages and libraries on your Mac. 

The `eksctl` tool that we need is in the Weaveworks repository and is not part of the "core" packages included in Homebrew. So, we will use a Homebrew tap to add the repository to our local Homebrew. Taps allow you to extend the range of available software packages beyond what is included in the main Homebrew repository.

The following `brew` commands will add Weaveworks to our local Homebrew and then install the `eksctl` tool from it.


```
brew tap weaveworks/tap

brew install weaveworks/tap/eksctl
```

**We are going to create an IAM user with admin privs to create and own this whole cluster.**

In the web management UI for AWS, go to IAM settings and create a user with admin privileges but no management console access. We created a user called "K8-Admin"

Delete or rename your `~/.aws/credentials` file and re-run `aws configure` with the new user's Access and secret access keys.

### Deploying a cluster with `eksctl`

Run the `eksctl` command below to create your first cluster and perform the following:

-   Create a 3-node Kubernetes cluster named `sterling-east` with one node type as `m5.xlarge` and region as `us-east-1`.
-   Define a minimum of one node (`--nodes-min 1`) and a maximum of three-node (`--nodes-max 3`) for this node group managed by EKS. The node group is named `sterling-workers`.
-   Create a node group with the name `sterling-workers` and select a machine type for the `sterling-workers` node group.

```tsx
eksctl create cluster \
--name sterling-east \
--version 1.24 \
--region us-east-1 \
--with-oidc \
--zones us-east-1a,us-east-1b,us-east-1c \
--nodegroup-name sterling-workers \
--node-type m5.xlarge \
--nodes 3 \
--nodes-min 1 \
--nodes-max 3 \
--tags "Product=Sterling" \
--managed
```
Associate an IAM oidc provider with the cluster if you didn't include `--with-oidc` above. Make sure to use the region you created the cluster in.
```
eksctl utils associate-iam-oidc-provider --region=us-east-1 --cluster=sterling-east --approve
```

Once the cluster is up, add it to your kube config. `eksctl` will probably do this for you.

```bash
aws eks update-kubeconfig --name sterling-east --region us-east-1
```

## Prepare the cluster

Create a namespace and set the context. This is where we will be living for the duration of the installation.
```
kubectl create namespace sterling

kubectl config set-context --current --namespace=sterling
```

### Install the EKS helm repo

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```
## Install the EBS driver to the cluster

### Download the example ebs iam policy

```
curl -o iam-policy-example-ebs.json https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/docs/example-iam-policy.json
```

Create the policy. You can change  `AmazonEKS_EBS_CSI_Driver_Policy` to a different name, but if you do, make sure to change it in later steps too.

```tsx
aws iam create-policy \
--policy-name AmazonEKS_EBS_CSI_Driver_Policy \
--policy-document file://iam-policy-example-ebs.json

{
    "Policy": {
        "PolicyName": "AmazonEKS_EBS_CSI_Driver_Policy",
        "PolicyId": "ANPA24LVTCGN5YOUAVX2V",
        "Arn": "arn:aws:iam::<ACCOUNTID>:policy/AmazonEKS_EBS_CSI_Driver_Policy",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2023-04-19T14:17:03+00:00",
        "UpdateDate": "2023-04-19T14:17:03+00:00"
    }
}

```
### Create the service account
Create the service account using the `arn` returned above.

```tsx
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster sterling-east \
  --attach-policy-arn arn:aws:iam::<ACCOUNTID>:policy/AmazonEKS_EBS_CSI_Driver_Policy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole
```

Create the addon for the cluster using the `arn` returned from the command above.
```tsx
eksctl create addon \
--name aws-ebs-csi-driver \
--cluster sterling-east \
--service-account-role-arn arn:aws:iam::<ACCOUNTID>:role/AmazonEKS_EBS_CSI_DriverRole \
--force
```
### Create the StorageClass
Create the following StorageClass yaml to use gp3

`gp3-sc.yaml`
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3-sc
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

Create the storage class
```tsx
kubectl apply -f gp3-sc.yaml
```
## Prepare EFS storage for the cluster

By default when we create a cluster with eksctl it defines and installs `gp2` storage class which is backed by Amazon's EBS (elastic block storage). Being block storage, it's not super happy supporting RWX in our cluster. We need to install an EFS storage class.

### Create an IAM policy and role

Create an IAM policy and assign it to an IAM role. The policy will allow the Amazon EFS driver to interact with your file system.

Download the example policy.
```tsx
curl -o iam-policy-example-efs.json https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json
```
Create the policy

```tsx
aws iam create-policy \
--policy-name AmazonEKS_EFS_CSI_Driver_Policy \
--policy-document file://iam-policy-example-efs.json

{
    "Policy": {
        "PolicyName": "AmazonEKS_EFS_CSI_Driver_Policy",
        "PolicyId": "ANPA24LVTCGN7YGDYRWJT",
        "Arn": "arn:aws:iam::<ACCOUNTID>:policy/AmazonEKS_EFS_CSI_Driver_Policy",
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
Create an IAM role and attach the IAM policy to it. Annotate the Kubernetes service account with the IAM role ARN and the IAM role with the Kubernetes service account name. You can create the role using `eksctl` or the AWS CLI. We're going to use `eksctl`, Also our `Arn` is returned in the output above, so we'll use it here.

```tsx
eksctl create iamserviceaccount \
    --cluster sterling-east \
    --namespace kube-system \
    --name efs-csi-controller-sa \
    --attach-policy-arn arn:aws:iam::<ACCOUNTID>:policy/AmazonEKS_EFS_CSI_Driver_Policy \
    --approve \
    --region us-east-1
```
Now we just need our add-on registry address. This can be found here: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html

### Install the driver add-on
Let's install the driver add-on to our clusters. We're going to use `helm` for this.
```tsx
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/

helm repo update
```

Install a release of the driver using the Helm chart. Replace the repository address with the cluster's [container image address](https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html).


```tsx
helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
    --namespace kube-system \
    --set image.repository=602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-efs-csi-driver \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=efs-csi-controller-sa

```

### Create the filesystem
Now we need to create the filesystem in EFS so we can use it

```tsx
export clustername=sterling-east
export region=us-east-1
```
Get our VPC ID
```tsx
vpc_id=$(aws eks describe-cluster \
    --name $clustername \
    --query "cluster.resourcesVpcConfig.vpcId" \
    --region $region \
    --output text)
```

Retrieve the CIDR range for your cluster's VPC and store it in a variable for use in a later step.

```tsx
cidr_range=$(aws ec2 describe-vpcs \
    --vpc-ids $vpc_id \
    --query "Vpcs[].CidrBlock" \
    --output text \
    --region $region)
```

Create a security group with an inbound rule that allows inbound NFS traffic for your Amazon EFS mount points.

```tsx
security_group_id=$(aws ec2 create-security-group \
    --group-name EFS4SterlingSecurityGroup \
    --description "EFS security group for sterling Clusters" \
    --vpc-id $vpc_id \
    --region $region \
    --output text)
```

Create an inbound rule that allows inbound NFS traffic from the CIDR for your cluster's VPC.

```tsx
aws ec2 authorize-security-group-ingress \
    --group-id $security_group_id \
    --protocol tcp \
    --port 2049 \
    --region $region \
    --cidr $cidr_range
```

Create a file system.
```tsx
file_system_id=$(aws efs create-file-system \
    --region $region \
    --encrypted \
    --performance-mode generalPurpose \
    --query 'FileSystemId' \
    --output text)
```

### Create the mount targets
Create mount targets.

Determine the IDs of the subnets in your VPC and which Availability Zone the subnet is in.
```tsx
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
Add mount targets for the subnets that your nodes are in.

Run the following command:
```bash
for subnet in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[*].{SubnetId: SubnetId,AvailabilityZone: AvailabilityZone,CidrBlock: CidrBlock}' --region $region --output text | awk '{print $3}') ; do aws efs create-mount-target --file-system-id $file_system_id --region $region --subnet-id $subnet --security-groups $security_group_id ; done
```

This wraps the below command in a for loop that will iterate through your subnet ids.
```tsx
aws efs create-mount-target \
    --file-system-id $file_system_id \
    --region $region \
    --subnet-id <SUBNETID> \
    --security-groups $security_group_id
```

### Create the storage classes
Create a storage class for dynamic provisioning

Let's get our filesystem ID if we don't already have it above. However if you ran the above steps, `$file_system_id` should already be defined.
```tsx
aws efs describe-file-systems \
--query "FileSystems[*].FileSystemId" \
--region $region \
--output text

fs-071439ffb7e10b67b
```

Download a `StorageClass` manifest for Amazon EFS.
```tsx
curl -o EFSStorageClass.yaml https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/examples/kubernetes/dynamic_provisioning/specs/storageclass.yaml

```
Configure two separate EFS storage classes, one for Sterling and one for MQ. The reason for this is MQ requires specific userids to work happily when using shared storage whereas Sterling requires its own user to own stuff and might cause conflicts. By specifying separate classes we eliminate the problem. Make sure the `fileSystemId` is the same for both.

Update it with the storage class id

```bash
sed -i 's/fileSystemId:.*/fileSystemId: fs-071439ffb7e10b67b/' EFSStorageClass.yaml
```

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

```bash
kubectl apply -f EFSStorageClass.yaml
```

Finally, verify it's there
```tsx


kubectl get sc
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
efs-mq-sc          efs.csi.aws.com         Delete          Immediate              false                  7s
efs-sfg-sc          efs.csi.aws.com         Delete          Immediate              false                  7s
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  13d
```

## Install the Loadbalancer controller

Let's install the loadbalancer controller to the cluster

### Create the IAM Policy

Download an IAM policy for the AWS Load Balancer Controller that allows it to make calls to AWS APIs on your behalf.

```bash
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json
```

Create an IAM policy using the policy downloaded in the previous step.

```tsx
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

{
    "Policy": {
        "PolicyName": "AWSLoadBalancerControllerIAMPolicy",
        "PolicyId": "ANPA24LVTCGNV55JFAAP5",
        "Arn": "arn:aws:iam::<ACCOUNTID>:policy/AWSLoadBalancerControllerIAMPolicy",
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

Create an IAM role. Create a Kubernetes service account named `aws-load-balancer-controller` in the `kube-system` namespace for the AWS Load Balancer Controller and annotate the Kubernetes service account with the name of the IAM role.


```bash
eksctl create iamserviceaccount \
  --cluster=sterling-east \
  --namespace=kube-system \
  --name=aws-load-balancer-controller-sterling \
  --role-name AmazonEKSsterlingLoadBalancerControllerRolesterling \
  --attach-policy-arn=arn:aws:iam::<ACCOUNTID>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```

### Install the AWS Load Balancer Controller.

```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=sterling-east \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller-sterling

NAME: aws-load-balancer-controller
LAST DEPLOYED: Tue Jan 17 15:33:50 2023
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
AWS Load Balancer controller installed!

```

## Install the NGINX Controller

### Get the NGINX controller deployment
Pull down the NGINX controller deployment

```bash
wget -O nginx-deploy.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml
```

Modify the deployment file and add the following annotations

```tsx
service.beta.kubernetes.io/aws-load-balancer-type: "external"
service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
```

### Apply the deployment

```bash
kubectl apply -f nginx-deploy.yaml
```

### Verify the deployment

Command:

```bash
kubectl get ingressclass
NAME    CONTROLLER             PARAMETERS   AGE
alb     ingress.k8s.aws/alb    <none>       6d10h
nginx   k8s.io/ingress-nginx   <none>       7d
```

## Security RBACS

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

## Security Policies

With Kubernetes v1.25, Pod Security Policy (PSP) API has been removed and replaced with Pod Security Admission (PSA) contoller. Kubernetes PSA conroller enforces predefined Pod Security levels at the namespace level. The Kubernetes Pod Security Standards defines three different levels: privileged, baseline, and restricted. Refer to Kubernetes [`Pod Security Standards`] ([https://kubernetes.io/docs/concepts/security/pod-security-standards/](https://kubernetes.io/docs/concepts/security/pod-security-standards/)) documentation for more details. This chart is compatible with the restricted security level.

The version of kubernetes in EKS in our instance is 1.24. So the following policies would be applied. Below is an optional custom PSP definition based on the IBM restricted PSP.

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

## AWS RDS/DB

For this installation we will be using an Oracle Database hosted in AWS RDS.

### Create the security group

Create a security group. We're going to get our vpc for our sterling cluster first and use that here since we don't have any default vpc.

Let's export the following env vars
```
export clustername=sterling-east
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

### Retrieve the CIDR range for the cluster VPC

Retrieve the CIDR range for your cluster's VPC and store it in a variable for use in a later step.

```
cidr_range=$(aws ec2 describe-vpcs \
    --vpc-ids $vpc_id \
    --query "Vpcs[].CidrBlock" \
    --output text \
    --region $region)
```

### Authorized access to that group

Let's authorize access to that group for Oracle which uses port 1521

```
aws ec2 authorize-security-group-ingress \
    --group-id $security_group_id \
    --protocol tcp \
    --port 1521 \
    --region $region \
    --cidr $cidr_range
```

### Create the DB Subnet Group

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

### Create the RDS DB instance

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

A default DB called `ORCL` will be created with a default admin user `oracleuser` with the password `oraclepass`.

## Configure the Oracle Instance

### Create a client pod

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

### Connect to the client pod

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

### Configure database

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

## Deploy IBM MQ to the cluster

### Create MQ Namespace (optional)
Create a new namespace for MQ. This is optional if you'd rather just run MQ in the same namespace as Sterling b2bi then skip this step.

```
kubectl create namespace mqsterling
```

Set our context to it

```
kubectl config set-context --current --namespace=mqsterling
```

### Create an MQ overrides file

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
    enable: true
  multiinstance:
    enable: false

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
    webconsole: false
    mqtraffic: true
  loadBalancer:
    webconsole: false
    mqtraffic: true
  ingress:
    webconsole:
      enable: false
      hostname:
      path: /ibmmq
      tls:
        enable: false
```
### Install IBM MQ 

Install IBM MQ with the following command

```
helm install sterlingmq ibm-messaging-mq/ibm-mq \
-f sterling_values.yaml \
--set "queueManager.envVariables[0].name=MQ_ADMIN_PASSWORD" \
--set "queueManager.envVariables[0].value=mqpasswd" \
--set "queueManager.envVariables[1].name=MQ_APP_PASSWORD" \
--set "queueManager.envVariables[1].value=mqpasswd"
```

The command above will create a loadbalancer with port 1414 as the access port for the queue manager.

### Create the MQ Secret.

This needs to be created in the sterling namespace where B2Bi will be installed.

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

### Retrieve MQ's cluster-ip

Retrieve the cluster-ip of MQ's loadbalancer and make a note of it:

If you created a separate namespace for MQ
```
kubectl get services -n mqsterling
```
If MQ is in the same namespace (sterling)

```
kubectl get services -n sterling
```

Output:
```
NAME                             TYPE           CLUSTER-IP       EXTERNAL-IP                                                                     PORT(S)             AGE
sterlingmq-ibm-mq                ClusterIP      10.100.251.229   <none>                                                                          9443/TCP,1414/TCP   70d
sterlingmq-ibm-mq-loadbalancer   LoadBalancer   10.100.98.89     k8s-mqsterli-sterling-6c00100a47-92a6027e40f34c81.elb.us-east-1.amazonaws.com   1414:30516/TCP      70d
sterlingmq-ibm-mq-metrics        ClusterIP      10.100.21.87     <none>                                                                          9157/TCP            70d
sterlingmq-ibm-mq-qm             NodePort       10.100.146.149   <none>                                                                          1414:30038/TCP      70d
sterlingmq-ibm-mq-web            NodePort       10.100.183.242   <none>                                                                          9443:32013/TCP      70d
```
In the above return output, our cluster-ip for the loadbalancer for MQ is `10.100.98.89`.

## Role Based S3 access

You will need the following items if you are setting this up on a pre-existing S3 bucket:

1. Bucket name
2. OIDC Provider: 

If you have an OIDC provider already associated with your eks cluster, you can retrieve that info with this command:
```
aws eks describe-cluster \
--name <CLUSTERNAME> \
--query "cluster.identity.oidc.issuer" \
--output text | sed "s/https:\/\///"

oidc.eks.us-east-1.amazonaws.com/id/9FD6ABAF8C2FCBAC9E899C79ACE7DF62
```
3. KMS Key arn (if using KMS)
4. Account ID

The rest of these instructions assume the creation of all these elements.

### Bucket Creation

Let us create an S3 bucket to use for file transfers. 

```
aws s3api create-bucket \
--bucket b2bis3bucket \
--region us-east-1 \
--object-ownership BucketOwnerEnforced
```
This creates a standard bucket in the us-east-1 region that is bucket owner enforced and default encrypted with Server-side encryption with Amazon S3 managed keys (SSE-S3).

### Using KMS Encryption keys on S3 bucket (optional)

By default AWS S3 buckets are encrypted with AWS SSE (server side encrypted) managed keys. But creating customer managed keys are also an option. 

Create a KMS key

```
aws kms create-key

{
    "KeyMetadata": {
        "AWSAccountId": <ACCOUNTID>,
        "KeyId": "413d348e-1307-42a7-bb92-206017e8d81c",
        "Arn": "arn:aws:kms:us-east-1:<ACCOUNTID>:key/413d348e-1307-42a7-bb92-206017e8d81c",
        "CreationDate": "2023-06-20T15:58:39.275000-04:00",
        "Enabled": true,
        "Description": "",
        "KeyUsage": "ENCRYPT_DECRYPT",
        "KeyState": "Enabled",
        "Origin": "AWS_KMS",
        "KeyManager": "CUSTOMER",
        "CustomerMasterKeySpec": "SYMMETRIC_DEFAULT",
        "KeySpec": "SYMMETRIC_DEFAULT",
        "EncryptionAlgorithms": [
            "SYMMETRIC_DEFAULT"
        ],
        "MultiRegion": false
    }
}
```

Make a note of the returned key ARN `"Arn": "arn:aws:kms:us-east-1:<ACCOUNTID>:key/413d348e-1307-42a7-bb92-206017e8d81c",` as we will need it below if we are going to use KMS encryption.

Using the "KeyId" returned above, let's create a key alias:

```
aws kms create-alias \
--alias-name alias/example-kms-key \
--target-key-id "413d348e-1307-42a7-bb92-206017e8d81c"
```

Now let's grab the alias ARN for the key we created:

```
aws kms list-aliases --query "Aliases[].AliasArn" | grep example-kms-key

"arn:aws:kms:us-east-1:<ACCOUNTID>:alias/example-kms-key"
```

And now set the default symmetric encryption to our bucket using our new KMS key

```
aws s3api put-bucket-encryption \
--bucket b2bis3bucket \
--server-side-encryption-configuration '{ "Rules": [ { "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "aws:kms", "KMSMasterKeyID": "arn:aws:kms:us-east-1:<ACCOUNTID>:alias/example-kms-key"}, "BucketKeyEnabled": true } ] }'
```

### Create an OIDC provider

For the EKS cluster created, by default there will be an OIDC issuer URL associated with it. To use the IAM role for the service account, the OIDC provider needs to exist with OIDC issuer URL. To create the OIDC provider, we will use eksctl command line utility. For the record, we should have alread done this when we created our cluster.

```
eksctl utils associate-iam-oidc-provider \
--cluster sterling \
--approve
```

### Create an IAM policy

Create the file `s3-policy.json` with the below contents. Setting the KMS actions and key arn under `Resource` is only relevant if you are using KMS keys for bucket encryption. These Actions and Resources MUST be set if you plan on using KMS.

`s3-policy.json`
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject",
                "kms:GenerateDataKey",
                "kms:Decrypt"
            ],
            "Resource": [
                "arn:aws:kms:us-east-1:<ACCOUNTID>:key/413d348e-1307-42a7-bb92-206017e8d81c"
                "arn:aws:s3:::b2bis3bucket/*",
                "arn:aws:s3:::b2bis3bucket"
            ]
        }
    ]
}
```

This above policy will allow acces to objects in our S3 bucket that we've named `b2bis3bucket`. If using KMS, you need the key that is attached to your bucket associated as a resource otherwise you will not have the permissions to run `kms:GenerateDataKey` or `kms:Decrypt`.

Now apply the policy

```
aws iam create-policy --policy-name s3-policy --policy-document file://s3-policy.json

{
    "Policy": {
        "PolicyName": "s3-policy",
        "PolicyId": "ANPA24LVTCGNY64GFVKI3",
        "Arn": "arn:aws:iam::<ACCOUNTID>:policy/s3-policy",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2023-05-11T20:01:29+00:00",
        "UpdateDate": "2023-05-11T20:01:29+00:00"
    }
}
```

Make a note of the ARN value returned for the policy created.

### Create a service account

Create a file `demo-service-account.yaml`. We have to create a Kubernetes service account with the name `demo-sa` in our relevant namespace using the below yaml file.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: demo-sa
  namespace: sterling
```

Now apply the below command to create a service account.

`kubectl apply -f demo-service-account.yaml`

### Create an IAM Role and attach the policy

Using your account ID, build an arn value and add it to the OIDC provider that we retrieved above. Bear in mind that `"system:serviceaccount:sterling:demo-sa"` needs to have the service account name you created in case you created it with a name other than `demo-sa`. 

Create the following JSON.

`demo-role-relationship.json`
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT>:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/9FD6ABAF8C2FCBAC9E899C79ACE7DF62"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-east-1.amazonaws.com/id/9FD6ABAF8C2FCBAC9E899C79ACE7DF62:aud": "sts.amazonaws.com",
          "oidc.eks.us-east-1.amazonaws.com/id/9FD6ABAF8C2FCBAC9E899C79ACE7DF62:sub": "system:serviceaccount:sterling:demo-sa"
        }
      }
    }
  ]
}
```

Now create the role
```bash
aws iam create-role \
--role-name s3-role \
--assume-role-policy-document file://demo-role-relationship.json

{
    "Role": {
        "Path": "/",
        "RoleName": "s3-role",
        "RoleId": "AROA24LVTCGNY4A64ECOQ",
        "Arn": "arn:aws:iam::<ACCOUNTID>:role/s3-role",
        "CreateDate": "2023-05-11T20:16:17+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Federated": "arn:aws:iam::<ACCOUNTID>:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/9FD6ABAF8C2FCBAC9E899C79ACE7DF62"
                    },
                    "Action": "sts:AssumeRoleWithWebIdentity",
                    "Condition": {
                        "StringEquals": {
                            "oidc.eks.us-east-1.amazonaws.com/id/9FD6ABAF8C2FCBAC9E899C79ACE7DF62:aud": "sts.amazonaws.com",
                            "oidc.eks.us-east-1.amazonaws.com/id/9FD6ABAF8C2FCBAC9E899C79ACE7DF62:sub": "system:serviceaccount:demo-s3:demo-sa"
                        }
                    }
                }
            ]
        }
    }
}
```

Take note of the ARN value returned for the role we created `arn:aws:iam::<ACCOUNTID>:role/s3-role` as we will need it below.

Attach the policy we created to the new role using the arn returned above.

```
aws iam attach-role-policy \
--role-name s3-role \
--policy-arn=arn:aws:iam::<ACCOUNTID>:policy/s3-policy
```

### Annotate the service account with the IAM role

The service account needs to be annotated to the IAM role using the below command. This can be retrieved from the output of the role creation.

```
kubectl annotate serviceaccount -n sterling demo-sa eks.amazonaws.com/role-arn=arn:aws:iam::<ACCOUNTID>:role/s3-role
```

## Wrap Up

In the steps above, we have performed the following:

1. Setup aws client
2. Setup `eskctl`
3. Created a cluster
4. Installed `efs` storage controller
5. Installed `ebs` storage controller
6. Installed the loadbalancer controller
7. Installed the NGINX ingress controller
8. Set up the required Security policies and RBACs
9. Created an AWS RDS Oracle Instance and configured it
10. Created an S3 bucket and assigned role based authentication

## Links

[AWS Configuring Bucket Keys](https://docs.aws.amazon.com/AmazonS3/latest/userguide/configuring-bucket-key.html)