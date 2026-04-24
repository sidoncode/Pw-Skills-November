# Kubernetes Controllers - Simple Tutorial

## Start Minikube
```bash
minikube start
```

## Create namespace
```bash
kubectl create ns demo
kubectl config set-context --current --namespace=demo
```

---

## Part 1: Standalone Pod (NO controller)

```bash
# Create pod
kubectl run my-pod --image=nginx

# Check it
kubectl get pods

# Delete it
kubectl delete pod my-pod

# Check again - IT'S GONE
kubectl get pods
```

**Result: Pod deleted = Gone forever ❌**

---

## Part 2: Deployment (WITH controller)

```bash
# Create deployment
kubectl create deployment myapp --image=nginx

# Check it
kubectl get pods

# Delete the pod
kubectl delete pod $(kubectl get pods -o jsonpath='{.items[0].metadata.name}')

# Check again - NEW POD CREATED
kubectl get pods
```

**Result: Pod deleted = Auto-recreated ✅**

---

## Part 3: Scale Pods

```bash
# Scale to 3 pods
kubectl scale deployment myapp --replicas=3

# Check it
kubectl get pods

# Delete one pod
kubectl delete pod $(kubectl get pods -o jsonpath='{.items[0].metadata.name}')

# Check - still 3 pods (new one created)
kubectl get pods
```

**Result: Always maintains 3 pods ✅**

---

---

## Part 4: Update Image (Rolling Update)

```bash
# Check current image
kubectl describe deployment myapp | grep Image

# Update image
kubectl set image deployment/myapp myapp=nginx:alpine

# Check - pods are being recreated with new image
kubectl get pods

# Verify new image
kubectl describe deployment myapp | grep Image
```

**Result: Old pods replaced with new image, no downtime ✅**

---

## Part 5: ReplicaSet (Lower-level controller)

```bash
# Create ReplicaSet
cat > rs.yaml << 'EOF'
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: web-rs
spec:
  replicas: 2
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      labels:
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.19
EOF

# Apply it
kubectl apply -f rs.yaml

# Check pods
kubectl get pods

# Delete one pod
kubectl delete pod $(kubectl get pods -l tier=frontend -o jsonpath='{.items[0].metadata.name}')

# Check - new pod created
kubectl get pods
```

**Result: ReplicaSet maintains 2 pods automatically ✅**

---

## Part 6: Describe and Debug Commands

```bash
# Get detailed deployment info
kubectl describe deployment myapp

# Get detailed pod info
kubectl describe pod $(kubectl get pods -o jsonpath='{.items[0].metadata.name}')

# View pod logs
kubectl logs $(kubectl get pods -o jsonpath='{.items[0].metadata.name}')

# Get pods with more info (IP, Node, etc)
kubectl get pods -o wide
```

---

## Part 7: Namespaces

```bash
# Create namespaces
kubectl create ns dev
kubectl create ns prod

# Create deployment in dev namespace
kubectl -n dev create deployment app --image=nginx --replicas=2

# Create deployment in prod namespace
kubectl -n prod create deployment app --image=nginx --replicas=3

# Get pods in dev only
kubectl get pods -n dev

# Get pods in prod only
kubectl get pods -n prod

# Get all pods across all namespaces
kubectl get pods -A

# Switch context to dev namespace
kubectl config set-context --current --namespace=dev

# Delete namespace
kubectl delete ns dev
```

---

## Cleanup

```bash
kubectl delete ns demo
kubectl delete ns prod
```

---

## Key Difference

| | Standalone Pod | Deployment | ReplicaSet |
|---|---|---|---|
| Pod deleted | GONE ❌ | Auto-recreates ✅ | Auto-recreates ✅ |
| Scale | Manual | `--replicas=N` | `--replicas=N` |
| Update image | Manual | Automatic | Requires Deployment |
| Best for | Learning | Production (99%) | Low-level control |
