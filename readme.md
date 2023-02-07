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
#### **AWS Account:**
Configuring AWS Cli
#### CMDLINE Client install (MacOS)

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
#### **EKS Cluster**

The tool to use for managing EKS is called `eksctl`.

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

Create a namespace and set the context
```
kubectl create namespace sterling

kubectl config set-context --current --namespace=sterling
```

Add the appropriate security policies

The following sample file illustrates RBAC for the default service account with the target namespace as `sterling`

Create a file called `sterling-rbac.yaml`

```
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ibm-b2bi-role-sterling
  namespace: sterling
rules:
  - apiGroups: ['route.openshift.io']
    resources: ['routes','routes/custom-host']
    verbs: ['get', 'watch', 'list', 'patch', 'update']
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

#### **RDS/DB Schema**

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
#### **Registry - images**
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
kubectl create secret docker-registry sterling-secret --docker-server="https://748107796891.dkr.ecr.us-east-1.amazonaws.com/sterling-mft-repo" \
--docker-username=AWS \
--docker-password=$login_passwd \
--docker-email="kramerro@us.ibm.com"
```
---
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
