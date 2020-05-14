### Cleanup


```
kubectl delete --all pods --namespace=default
kubectl delete --all pods --namespace=nginx-ingress
kubectl delete --all deployments --namespace=default
kubectl delete --all deployments --namespace=nginx-ingress
cd terraform
terraform destroy
```
