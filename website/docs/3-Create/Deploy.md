---
id: solution-deploy
sidebar_position: 1
title: Deploy
---

# Sterling Installation

## Required secrets

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

## Sidecar Deployment

In order to upload the required jdbc drivers that b2bi will need to talk to the database, we must create a sidecar pod with a storage volume that will be shared.

### Generate the yaml file

Create the following file

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

### Create the sidecar pod and volume

```
kubectl apply -f sterlingtoolkitdeploy.yaml
```

### Retrieve the JDBC driver and stage it to the pod

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
## Download the Sterling helm charts

The following link is for the required helm charts for this installation. If you haven't already pulled this down, do it now.

[ibm-b2bi-prod-2.1.3](https://github.com/IBM/charts/raw/master/repo/ibm-helm/ibm-b2bi-prod-2.1.3.tgz)

Download the `ibm-b2bi-prod` helm charts from the above link.

Extract the `ibm-b2bi-prod-2.1.3.tgz` file
```
tar zxvf ibm-b2bi-prod-2.1.3.tgz
```

Apply the patches included with this repo from the same directory you extracted the helm charts. There are also patches for 2.1.1 in that patch directory, but we are working with 2.1.3 of the helm charts.

```
patch -p0 < path/to/repo/patches/2.1.3/*.patch -V none

patching file 'ibm-b2bi-prod/templates/db-setup-job.yaml'
patching file 'ibm-b2bi-prod/templates/ext-purge-job.yaml'
patching file 'ibm-b2bi-prod/templates/post-delete-cleanup-job.yaml'
patching file 'ibm-b2bi-prod/templates/postinstall-patch-ingress-job.yaml'
patching file 'ibm-b2bi-prod/templates/preinstall-tls-setup-job.yaml'
patching file 'ibm-b2bi-prod/values.yaml'
patching file 'ibm-b2bi-prod/templates/ingress.yaml'
patching file 'ibm-b2bi-prod/templates/ac-backend-service.yaml'
patching file 'ibm-b2bi-prod/templates/asi-backend-service.yaml'
patching file 'ibm-b2bi-prod/templates/validation.tpl'
patching file 'ibm-b2bi-prod/values.yaml'

```

### Update our chart version

:::note

As of this writing, you will need to update the version in the `Chart.yaml` in version 2.1.3 and below.

:::

Update the Kubernetes version in the `Chart.yaml`

```
tar zxvf ibm-b2bi-prod-2.1.3.tgz
```

Apply the patches included with this repo from the same directory you extracted the helm charts. 

```
patch -p0 < path/to/repo/patches/*.patch

patching file 'ibm-b2bi-prod/templates/db-setup-job.yaml'
patching file 'ibm-b2bi-prod/templates/ext-purge-job.yaml'
patching file 'ibm-b2bi-prod/templates/post-delete-cleanup-job.yaml'
patching file 'ibm-b2bi-prod/templates/postinstall-patch-ingress-job.yaml'
patching file 'ibm-b2bi-prod/templates/preinstall-tls-setup-job.yaml'
patching file 'ibm-b2bi-prod/values.yaml'
patching file 'ibm-b2bi-prod/templates/ingress.yaml'
patching file 'ibm-b2bi-prod/templates/ac-backend-service.yaml'
patching file 'ibm-b2bi-prod/templates/asi-backend-service.yaml'
patching file 'ibm-b2bi-prod/templates/validation.tpl'
patching file 'ibm-b2bi-prod/values.yaml'

```

### Update our chart version

:::note

As of this writing, you will need to update the version in the `Chart.yaml` in version 2.1.3 and below.

:::

Update the Kubernetes version in the `Chart.yaml`

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

Make a note of the `Server Version` and update the `Chart.yaml` file in the `ibm-b2bi-prod` directory.
```
sed -i "s/^kubeVersion:.*/kubeVersion: '>=v1.23.14-eks-ffeb93d'/" Chart.yaml
```

## Sterling Override File

This is valid for installing the Sterling B2BI product. 


[sterling-overrides-b2bi.yaml](../../../overrides/sterling-b2bi-values.yaml)

:::note

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

:::

### Update the overrides as required

Host entries for each ingress should match what your existing domain is if you don't have a dedicated FQDN. This means you should set a wildcard.

In our example, we are not using a custom domain so our ingress host entries look like the following in the overrides document for each application (ac, asi, api):

```
  ingress:
    internal:
      host: "*.amazonaws.com"
      tls:
        enabled: true
        secretName: sterling-b2bi-b2bi-ac-frontend-svc
      extraPaths: []
    external:
      host: "*.amazonaws.com" 
      tls:
        enabled: true
        secretName: sterling-b2bi-b2bi-ac-frontend-svc
      extraPaths: []
```

### Configuring Ingress in the overrides

Depending on whether you have installed the NGINX Ingress Controller or are using the native ALB Ingress, you will need to make the following updates to the overrides.


#### ALB Ingress

:::note

You may need to set `idle_timout.timeout_seconds` high as in the ingress annotations below as an `alb` ingress can sometimes cause an Gateway error 504 if the timeout is too low.

:::

```
ingress:
  enabled: true
  controller: "alb"
  annotations:
    alb.ingress.kubernetes.io/target-type: ip 
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=600
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/certificate-arn: '<CERT ARN>'
  port:
```

:::note

ALB Ingress requires a tls cert stored in AWS ACM. Follow this procedure to generate a cert and key and import it to ACM. If you have a FQDN to use for the host, set it here for the CN or use a wildcard for your domain. Our example uses `*.amazonaws.com` 

```
openssl genrsa 2048 -out alb-key.pem

openssl req -new -x509 -nodes -sha256 -days 999 -key alb-key.pem -outform PEM -out alb-cert.pem -subj "/C=US/ST=MA/L=Boston/O=IBM/OU=FSM/CN=*.amazonaws.com"
```

Import it into ACM with the following command. Region should be set to your cluster's region.

```
aws acm import-certificate \
--certificate fileb://alb-cert.pem \
--private-key fileb://alb-key.pem \
--region us-east-1 \
--tags "Key=cluster,Value=sterling-mft-east"

{
    "CertificateArn": "arn:aws:acm:us-east-1:748107796891:certificate/7aa410d2-7d5d-488d-918d-a9fdfed5d77f"
}

```
Take note of the returned CertificateArn as this is the value you need for `alb.ingress.kubernetes.io/certificate-arn:`

:::

#### NGINX Controller Ingress

```
ingress:
  enabled: true
  controller: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: 2000m
  port:
```

:::note

For NGINX we need to update `nginx.ingress.kubernetes.io/proxy-body-size:` to a high size in order to be able to upload large jar files to the B2Bi api.

:::

#### Ingress settings for each application

AC and ASI should have their own `ingress` entries that will look similar to this:

```
  ingress:
    internal:
      host: "*.amazonaws.com"
      tls:
        enabled: true
        secretName: sterling-b2bi-b2bi-ac-frontend-svc
      extraPaths: []
    external:
      host: "*.amazonaws.com"
      tls:
        enabled: true
        secretName: sterling-b2bi-b2bi-ac-frontend-svc
      extraPaths: []
```

Set the `host:` entry to either a wildcard for your custom domain or the fqdn you established if you are using your own domain. The `secretName:` should match the service:

```
sterling-b2bi-b2bi-asi-frontend-svc
sterling-b2bi-b2bi-ac-frontend-svc
sterling-b2bi-b2bi-api-frontend-svc

```

For API use the same logic as above and use your specific FQDN or your wildcarded domain:

```
  ingress:
    internal:
      host: "*.amazonaws.com"
      tls:
        enabled: true
        secretName: sterling-b2bi-b2bi-api-frontend-svc
```

### Setting MQ info in the overrides

Run the following sed commands on the overrides file. You should have the cluster-ip of the MQ service from a previous step in during Preparation:

```
sed -i "s/^jmsVendor:.*/jmsVendor: IBMMQ/" sterling-b2bi-values.yaml
sed -i "s/^jmsQueueName:.*/jmsQueueName: DEV.QUEUE.1/" sterling-b2bi-values.yaml
sed -i "s/^jmsHost:.*/jmsHost: 10.100.98.89/" sterling-b2bi-values.yaml
sed -i "s/^jmsChannel:.*/jmsChannel: DEV.APP.SVRCONN/" sterling-b2bi-values.yaml
sed -i "s/^jmsSecret:.*/jmsSecret: mq-secret/" sterling-b2bi-values.yaml
```

### Setting the Database info in the overrides

Run the following sed commands on the overrides file. Make sure you took note of the RDS url to access the RDS instance.

```
sed -i "s/^dbVendor:.*/dbVendor: Oracle/" sterling-b2bi-values.yaml
sed -i "s/^dbHost:.*/dbHost: sterling-mft-db.cehubq1eqcri.us-east-1.rds.amazonaws.com/" sterling-b2bi-values.yaml
sed -i "s/^dbPort:.*/dbPort: 1521/" sterling-b2bi-values.yaml
sed -i "s/^dbData:.*/dbData: ORCL/" sterling-b2bi-values.yaml
```

### Custom Network Policies

If your cluster is restrictive, you may need to add extra customPolicies to the overrides file. This can be found near the top and would resemble the following entries:

```
global:
  license: true
  image:
    repository: "cp.icr.io/cp/ibm-b2bi/b2bi"
    tag: "6.1.2.1"
    digest: sha256:7426e3f8d935f28135b3f2b9cd5bc653105af9609606da967cb1cf70ca0b49de
    pullPolicy: IfNotPresent
    pullSecret: "ibm-pull-secret"
  networkPolicies:
    ingress:
      enabled: true
      customPolicies:
    egress:
      enabled: true
// hightlight-start
      customPolicies:
      - name: allow-egress-to-rds
        toSelectors:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: b2bi
              release: sterling-b2bi
        - ipBlock:
            cidr: 192.168.99.219/32
        ports:
          - protocol: TCP
            port: 1521
      - name: allow-egress-to-cd
        toSelectors:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: b2bi
              release: sterling-b2bi
        - ipBlock:
            cidr: 192.168.99.219/32
        ports:
          - protocol: TCP
            port: 1366
      - name: allow-egress-to-s3
        toSelectors:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: b2bi
              release: sterling-b2bi
        - ipBlock:
            cidr: 0.0.0.0/0
        ports:
          - protocol: TCP
            port: 443
// highlight-end
```

In our above example we have added egress network policies to allow traffic from the pods to the following:
- RDS (AWS Database services)
- Connect:Direct
- S3 Buckets

### TLS SecretNames for ingress

When the tls option is enabled for each app container, the secretName is created by the creattls job that is run at the beginning of the installation. So that secret can be applied in advance to the overrides:

```
ac.ingress.external.tls.enabled = true

ac.ingress.external.tls.secretName = sterling-b2bi-b2bi-ac-frontend-svc

asi.ingress.external.tls.enabled = true

asi.ingress.external.tls.secretName = sterling-b2bi-b2bi-asi-frontend-svc

api.ingress.external.tls.enabled = true

api.ingress.external.tls.secretName = sterling-b2bi-b2bi-asi-frontend-svc
```

## Perform the Helm installation

Run the helm installation with the following command

```
helm install sterling-b2bi -f sterling-b2bi-values.yaml /path/to/ibm-b2bi-prod --timeout 3600s --namespace sterling
```

Installation should take approximately 40 minutes


### Application Validation

## Default Sterling Users:

| Role | User ID | Password |
|------|---------|----------|
| System Administrator | fg_sysadmin | password |
| Integration Architect | fg_architect | password |
| Route Provisioner |	fg_provisioner | password |
| Operator | fg_operator | password |


Relevant URL:
https://www.ibm.com/docs/en/b2b-integrator/6.1.2?topic=overview-sterling-file-gateway-tutorial