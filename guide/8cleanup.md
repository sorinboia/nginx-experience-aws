### Cleanup

In order to delete the resources created during this workshop, run the commands below:   

```
kubectl delete --all svc --namespace=nginx-ingress
kubectl delete --all svc --namespace=default
cd terraform
terraform destroy
```
  
  
Finally, delete the `NGINX-EKS` stack in the [CloudFormation console](https://eu-central-1.console.aws.amazon.com/cloudformation/home?region=eu-central-1#/).

:warning: Please note: it will also delete the Cloud9 instance.

  
  
### Feedback

The code in this repo is constantly under improvement.  

For any feedback or suggestions, either open an Issue on GitHub, or contact:  

Sorin - [@sorinboia](https://github.com/sorinboia) for any NGINX related 
Artiom - [@artioml](https://github.com/ArtiomL) for any AWS related
