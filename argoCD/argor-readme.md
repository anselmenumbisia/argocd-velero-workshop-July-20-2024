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
kubectl get svc
```
- Patch the service to expose the app using a ALB endpoint
```
kubectl patch svc guestbook-ui -n default -p '{"spec": {"type": "LoadBalancer"}}
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

