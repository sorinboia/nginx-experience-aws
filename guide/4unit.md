## Deploy your application with NGINX Unit Application Server

Our next step will be to deploy our application in the Kubernetes environment.  
As stated before these are the 4 microservices which we will deploy.
- Main - provides access to the web GUI of the application for use by browsers
- Backend - is a supporting microservice and provides support for the customer facing services only
- App2 - provides money transfer API based functionalities for both the Web app and third party consumer applications
- App3 - provides referral API based functionalities for both the Web app and third party consumer applications

Let deploy the app
Command:
> kubectl apply -f app/1arcadia.yaml

Output:
> deployment.apps/arcadia-main created  
  deployment.apps/arcadia-backend created  
  deployment.apps/arcadia-app2 created  
  deployment.apps/arcadia-app3 created  
  service/arcadia-main created  
  service/arcadia-backend created  
  service/arcadia-app2 created  
  service/arcadia-app3 created  

Let check that all is deployed and working as expected:  
Command:
> kubectl get nodes

Output:
> NAME                              READY   STATUS    RESTARTS   AGE  
  arcadia-app2-64ccdcdc97-2vn6w     1/1     Running   0          38s  
  arcadia-app3-5d76bf776b-sj446     1/1     Running   0          38s  
  arcadia-backend-bc96d5754-grwfn   1/1     Running   0          38s  
  arcadia-main-5d9bc94d55-cc597     1/1     Running   0          39s  

Command:
> kubectl get svc -owide

Output:
> NAME           TYPE           CLUSTER-IP       EXTERNAL-IP                                                                 PORT(S)        AGE    SELECTOR  
  arcadia-app2   ClusterIP      172.20.215.142   <none>                                                                      80/TCP         23m    app=arcadia-app2  
  arcadia-app3   ClusterIP      172.20.97.115    <none>                                                                      80/TCP         23m    app=arcadia-app3  
  arcadia-main   LoadBalancer   172.20.102.115   acd118a007f3749709373e5fed7206c3-436092828.eu-central-1.elb.amazonaws.com   80:32065/TCP   23m    app=arcadia-main  
  backend        ClusterIP      172.20.84.9      <none>                                                                      80/TCP         5s     app=arcadia-backend  
  kubernetes     ClusterIP      172.20.0.1       <none>                                                                      443/TCP        108m   <none>  

From the output above you can see that "arcadia-main" is the only service that we have exposed to the outside world.
Lets check the application is up and running by browsing to the "EXTERNAL-IP" of the Main service.  
In our example this will be acd118a007f3749709373e5fed7206c3-436092828.eu-central-1.elb.amazonaws.com .







