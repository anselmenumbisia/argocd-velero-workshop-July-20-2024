# Introduction and Demo for ArgoCD

# What is ArgoCD
Argo CD is a GitOps tool that syncs your Git repository with your kubernetes clusters. ArgoCD is also a declarative continuous delivery tool for Kubernetes. It can be used as a standalone tool or as a part of your CI/CD workflow to deliver needed resources to your clusters.
In order to manage infrastructure and application configurations aligned with GitOps, your Git repository must be the single source of truth. The desired state of your system should be versioned, expressed declaratively, and pulled automatically. This is where Argo CD comes in
# Requirements
- EKS Cluster setup
- Installed kubectl command-line tool. https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html

## 1. Install Argo CD

This will create a new namespace, argocd, where Argo CD services and application resources will live.

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## 2. Download Argo CD CLI

Download the latest Argo CD version from https://argo-cd.readthedocs.io/en/stable/cli_installation/. More detailed installation instructions can be found via the CLI installation documentation

## 3. Access The Argo CD API Server
By default, the Argo CD API server is not exposed with an external IP. To access the API server, choose one of the following techniques to expose the Argo CD API server:

#### a. Service Type Load Balancer¶
Change the argocd-server service type to LoadBalancer. Run the command below:

```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

Run the command to get your alb endpoint or rab it from your aws console int he region where you deployed your cluster
```
kubectl describe svc argocd-server -n argocd
```

#### b. Port Forwarding
Kubectl port-forwarding can also be used to connect to the API server without exposing the service. run the comman below:

```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
#### c. Access ArgoCD on the browser using load balancer endpoint gotten from step "a" above

# 4. Get your initial passowrd for ArgoCD login
The initial username is **admin** and the passowrd can be gottent after running the command
```
argocd admin initial-password -n argocd
```

# 5. Creating apps via UI
Now that you have successfully logged in to ArgoCd, lets create a new app.
- Click on **+ New App** and provide name to your app. Use the default project and leave sync policy as ***Manual***
- Connect the ***YOUR REPOSITORY URL*** repo to Argo CD by setting repository url to the github repo url, leave revision as ***HEAD***, and set the path to ***argo-guestbook-test-app***
- For Destination, set cluster URL to https://kubernetes.default.svc (or in-cluster for cluster name) and namespace to ***default***
- After filling out the information, click **Create** at the top of the UI to create the application
  
# 6. Sync/Deploy The Application
- Click on sync and select name of application created in previous step and sync the app to your ek cluster.

# 7. Access the app on the uI
- Navigate to your terminal  and run 

```
kubectl get svc -n prestigious
```
- Patch the service to expose the app using a ALB endpoint
```
kubectl patch svc -n prestigious guestbook-ui -p '{"spec": {"type": "LoadBalancer"}}'
```

Then run 
```
kubectl get svc -n prestigious guestbook-ui
```


This will display all services availabe in the default namespace.

# 8. Update k8s manifest for application in gihthub and push changes
- Navigate to the  ***argo-guestbook-test-app*** folder and open the ***guestbook-ui.yaml*** file 
- update replica from **1 to 3**
- Push changes back to github
```
git add .
git commit -m "modified deployment replicas"
git push
```


=======================================================================================================================================


# Use link for velero setup article 
https://katharharshal1.medium.com/backup-and-restore-eks-kubernetes-using-velero-32b11cb55b81

Prerequisites
- Access to a kubernetes Cluster v1.16 or later
- kubectl installed locally

Install Velero https://velero.io/docs/main/basic-install/#velero-on-windows 
- Windows:

```bash
choco install velero
```

- MacOs:
 
```bash
brew install velero
```

1. Create s3 bucket and provide any name of your choice

2. Create new IAM user or use exising IAM user and add the below permission to the user. Copy policy below and run in json encoder https://codebeautify.org/json-encode-online

   ***N.B replace ${VELERO_BUCKET} with S3 bucket name which we created for velero.***

   ```
   {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::${VELERO_BUCKET}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${VELERO_BUCKET}"
            ]
        }
    ]

   }


3. Add user credentials to your local system

```bash
aws configure
```

4. Verify installation of velero

```bash
velero version
```

5. Deploy velero on EKS 

***replace your bucket name, region, and credentials path in the command.***

```bash
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.10.0 \
    --bucket <bucketname>\
    --backup-location-config region=<region> \
    --snapshot-location-config region=<region> \
    --secret-file ~/.aws/credentials
```

6. Inspect the resources created

```bash
kubectl get all -n velero
```

# BACKUP and RESTORE

7. Deploy any test applications regardless of namespaces

After you set up the Velero server, you can clone the examples used in the following sections by running the following:

```bash
git clone https://github.com/vmware-tanzu/velero.git
cd velero
```

- Start the sample nginx app:
```bash
  kubectl apply -f examples/nginx-app/base.yaml
  ```
- Verify that resources are running
```bash
kubectl get po -n nginx-example
```
- Create a backup:
```bash
velero backup create nginx-backup --include-namespaces nginx-example
```
- Simulate a disaster:
```bash
kubectl delete namespaces nginx-example
```
- Wait for the namespace to be deleted. and then verify that nginx-example is deleted
```bash
kubectl get ns
```
- Restore your lost resources:
```bash
velero restore create --from-backup nginx-backup
```
- Verify that nginx-example is recreated and that resources are still running
```bash
kubectl get ns
kubectl get po -n nginx-example
```


# Here are some useful commands for velero :
## Backup:

```bash
# Create a backup every 6 hours with the @every notation
velero schedule create <SCHEDULE_NAME> --schedule="@every 6h"

# Create a daily backup of the namespace
velero schedule create <SCHEDULE_NAME> --schedule="@every 24h" --include-namespaces <namspacename>

# Create a weekly backup, each living for 90 days (2160 hours)
velero schedule create <SCHEDULE_NAME> --schedule="@every 168h" --ttl 2160h0m0s     
##default TTL time is 720h
# Create a backup including the test and default namespaces
velero backup create backup --include-namespaces test,default

# Create a backup excluding the kube-system and default namespaces
velero backup create backup --exclude-namespaces kube-system,default
# To backup entire cluster
velero backup create <BACKUPNAME>
#To backup namespace in a cluster
velero backup create <BACKUPNAME> --include-namespaces <NAMESPACENAME>

```

## Restore:

```bash
#Manual Restore
velero restore create --from-backup <backupname>
#Scheduled Backup
velero restore create <RESTORE_NAME> --from-schedule <SCHEDULE_NAME>
# Create a restore including the test and default namespaces
velero restore create --from-backup backup --include-namespaces nginx,default

# Create a restore excluding the kube-system and default namespaces
velero restore create --from-backup backup --exclude-namespaces kube-system,default
#Retrieve restore logs
velero restore logs <RESTORE_NAME>
```


# Uninstall VElero

```bash
velero uninstall
```