### AWS EKS


## step1: create  a IAM User with the following permissions
search -> IAM -> left side click on user -> create user

</br>
<img width="984" height="424" alt="image" src="https://github.com/user-attachments/assets/4d760cf6-eed2-4db8-9fa1-59617a9cc01e" />

</br>

click on attach policy directly:

</br>

<img width="1398" height="346" alt="image" src="https://github.com/user-attachments/assets/0d5ff012-e0fd-4e66-ae38-a4d3cbeb31fc" />

</br>

```

AdministratorAccess
AmazonEC2FullAccess
AmazonECS_FullAccess
AmazonEKS_CNI_Policy
AmazonEKSClusterPolicy
AmazonEKSComputePolicy
AmazonEKSWorkerNodePolicy
AWSCloudFormationFullAccess

```
## step2: after that -> create user -> security credentials
create access key -> click and create a access key

## step3: create and configure eks cluster
>> aws configure

```
eksctl create cluster \
  --name my-cluster \
  --region ap-south-1 \
  --node-type t3.medium \
  --nodes 2

```


</br>

```
kubectl get nodes
```

</br>

```
brew tap aws/tap
brew install aws/tap/eksctl
eksctl version
```

</br>

```
winget install -e --id Kubernetes.kubectl
winget install -e --id eksctl.eksctl
```
</br>

```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

verify:

kubectl get deployment metrics-server -n kube-system

```

</br>

```
deployment.yaml file

apiVersion: apps/v1
kind: Deployment
metadata:
  name: hpa-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hpa-demo
  template:
    metadata:
      labels:
        app: hpa-demo
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: 100m
          limits:
            cpu: 200m
        ports:
        - containerPort: 80

</br>

```

kubectl apply -f deployment.yaml

kubectl expose deployment hpa-demo --type=LoadBalancer --port=80

kubectl autoscale deployment hpa-demo \
  --cpu-percent=50 \
  --min=2 \
  --max=10



kubectl get hpa


kubectl run -i --tty load-generator --image=busybox /bin/sh


kubectl get hpa -w




