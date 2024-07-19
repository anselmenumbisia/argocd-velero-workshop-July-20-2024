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