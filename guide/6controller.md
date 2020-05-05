## The Nginx Controller

We have finished the first part of the publishing our application, now we want to publish our APIs to be used by third party organizations.  
We will acomplish this using two components:
- Nginx Controller which will be used as an API Management
- Nginx Container will be the API Micro gateway which will reside within the Kubernetes environment


The EC2 that we will use for Nginx Controller has already been deployed, we need to find the public IP address.
<pre>
Command:
tf state show "aws_instance.controller" | grep "public_ip"
Output:
    associate_public_ip_address  = true
    public_ip                    = "18.184.134.91"
</pre>


Https browse to the IP address of the Controller.
> username: s@s.com  
> password: sorin2019

Next step is to get the API key to connect the microgateway so it is managed by the controller.
One you login the first thing you will see is the API key, save it for later.

Now lets deploy the microgateway with the following configuration and don't forget to replace the IP address and API key of the controller:
<pre>
apiVersion: apps/v1
kind: Deployment
metadata:
  name: microgateway
spec:
  replicas: 1
  selector:
    matchLabels:
      app: microgateway

  template:
    metadata:
      labels:
        app: microgateway
    spec:
      containers:
        - name: microgateway1
          image: sorinboia/ngtest:3.4
          imagePullPolicy: Always
          env:
            - name: API_KEY
              value: REPLACE WITH THE API KEY
            - name: CTRL_HOST
              value: REPLACE WITH CONTROLLER IP ADDRESS
            - name: HOSTNAME
              value: microgateway1            
          ports:
            - containerPort: 80
          readinessProbe:
            exec:
              command:
                - curl
                - 127.0.0.1:49151/api
            initialDelaySeconds: 5
            periodSeconds: 5
            
---

apiVersion: v1
kind: Service
metadata:
  name: microgateway
spec:
  selector:
    app: microgateway
  ports:
    - port: 80
      targetPort: 80
      name: http
    - port: 443
      targetPort: 443
      name: https
  externalTrafficPolicy: Local
  type: LoadBalancer
</pre>

From now on we will only use the Controller GUI do to all of our configuration.  
The end goal will be to expose and protect our APIs both internally within the cluster and externally to other programmers.  
Login to the Nginx Controller web UI, click the "N" button on the upper left side and go to "Instances".  
You will see listed the microgateway we just deployed. If it is not there wait 2 minutes, it takes a little bit of time for the instance to register.

Lets get the IP/fqdn of the microgateway service we just published, we will use it later on within our config.
<pre>
Command:
kubectl get svc microgateway

Output:
NAME           TYPE           CLUSTER-IP     EXTERNAL-IP                                                                 PORT(S)                      AGE
microgateway   LoadBalancer   172.20.181.0   ae0aa9bf7704745fbb2a47da2c3a2039-258004477.eu-central-1.elb.amazonaws.com   80:31424/TCP,443:32040/TCP   21h
</pre>


Now we will build our configuration:
##### "N" -> "Services" -> "Environments" -> "Create"  
Enter in all the field the following value "prod".  
Click on "View Api Request".  
All configuration on the Nginx Controller can easlly automated with external orchestration systems, this view can help you in understanding how to generate the configuration API calls.
The output will look like this:
<pre>
{
  "metadata": {
    "name": "prod",
    "displayName": "prod",
    "description": "prod",
    "tags": [
      "prod"
    ]
  },
  "desiredState": {}
}
</pre> 

##### "N" -> "Services" -> "Certs" -> "Create"
> Name: sorin-wild  
> Environment: prod  
> Upload key and certificate from the "cert" directory


##### "N" -> "Services" -> "Gateways" -> "Create"
> Name: api.arcadia.sorinb.cloud   
> Environment: prod  
> Instance Refs: Select All  
> Hostname: https://<EXTERNAL-IP OF THE "microgateway" SERVICE>  
> Cert Reference: sorin-wild

##### "N" -> "Services" -> "Apps" -> "Create"
> Name: arcadia-api   
> Environment: prod  


So far we have created an environment, uploaded the certificate/key that we will use gor our https connection, created a gateway which represent our entry point within the API gateway and last defined a new application object.  
Next we are going to publish the application APIs to the world, there are two aways of creating this configuration, the first one is manual and the second one is described bellow.
The developers of the Arcadia application as part of their development cycle are generating an [OpenApi](https://swagger.io/docs/specification/about/) specification do describe their APIs.  
We are going to use this API specification in order to publish the services to the world.

Open Postman and change in the environment variables the "controller_ip" to point to the IP address of the Nginx Controller we've just deployed.  
1. Run the "Log in to NGINX Controller" request
2. Run the "Create Arcadia OpenAPI Spec"  

We have just uploaded the OpenApi spec to the Nginx Controller.  
Go to "N" -> "APIs" -> "API Definitions". You can see listed the "Arcadia API" definition.  
 Click the "Pen" icon of the "Arcadia API" and you can see a list of the defined APIs endpoints.  
 
 Now we are going to check the DNS name of the backend servers we need to point to:
 <pre>
 Command:
 kubectl get svc
 
 Output:
 NAME              TYPE           CLUSTER-IP       EXTERNAL-IP                                                                 PORT(S)                      AGE
 arcadia-app2      ClusterIP      172.20.103.189   none                                                                        80/TCP                       171m
 arcadia-app3      ClusterIP      172.20.238.13    none                                                                        80/TCP                       171m
 arcadia-backend   ClusterIP      172.20.228.83    none                                                                        80/TCP                       109m
 arcadia-main      ClusterIP      172.20.166.2     none                                                                        80/TCP                       7s
 backend           ClusterIP      172.20.44.133    none                                                                        80/TCP                       171m
 kubernetes        ClusterIP      172.20.0.1       none                                                                        443/TCP                      8h
 microgateway      LoadBalancer   172.20.81.110    a2fa7314165114fb9b16ebd92a890078-367878391.eu-central-1.elb.amazonaws.com   80:32293/TCP,443:32428/TCP   12m
 </pre>

We are interested in "main" and "app2" and their DNS names are "arcadia-main" and "arcadia-app2".

##### "N" -> "Services" -> "APIs" -> "Workload Groups" -> "Create"
Create the configuration of each of the "Work loads"
> Name: arcadia-app2  
> Click Save  

Add workload
> First input: arcadia-app2  
> Port: 80  

Repeat the steps above for "arcadia-main".  
Return to "N" -> "Services"-> "APIs" -> "API Definitions" -> "Pen" Icon -> "Add a published API"
> Published API Name: arcadia-pub-api  
> Environment: prod  
> Application: arcadia-api  
> Gateways: api.arcadia.sorinb.cloud  
> Save  
> Add a route  
> All URLs that start with /api assign work load "arcadia-app2". 
> All URLs that start with /trading assign work load "arcadia-main".  
> After adding each route click Save.
> When done click "Publish"

Once the public API has been published we need to take the same procedure and do the same for the internal APIs that are accessing the Arcadia Backend service.  

##### "N" -> "Services" -> "Environments" -> "Create"  
> Name: internal
> Tags: internal

##### "N" -> "Services" -> "Gateways" -> "Create"
> Name: backend 
> Environment: internal  
> Instance Refs: Select All  
> Hostname: http://backend  


##### "N" -> "Services" -> "Apps" -> "Create"
> Name: arcadia-backend   
> Environment: internal

We could continue and import the OpenApi spec of the backend service as before but now we want to present the load balancing configuration when developers don't have the spec at hand.

##### "N" -> "Services" -> "Apps" -> "arcadia-backend" -> "Create Component"  
> Name: backend-component  
> Error Log: V   
> Access Log: V    
> Gateway Refs: backend  
> URIs: /  
> Workload Group Name: arcadia-backend    
> URI: http://arcadia-backend

Now we just need to tell kubernetes to point to the microgateway instead of directly to the pods.
<pre>
apiVersion: v1
kind: Service
metadata:
  name: backend
  labels:
    app: microgateway
spec:
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: microgateway
</pre>


Next we are going to test an API call to our published APIs.  
Run the Postman request "Transfer Money - No Auth". You should receive a success message and if you go to the main application and refresh the page you will be able to see the trasaction we just did in the "Transfer History" location.

All looks good but we are not done, we should add some security to our API and enable access with access keys.

##### "N" -> "Services" -> "APIs" -> "Identity Provider" -> "Create an Identity Provider"
> Name: api-protect  
> Environment: prod  
> Type: API Key
> Create  
> Create a client  
> Name: test  
> Save

Copy the key and update the postman environment variable "api_key"

###### "N" -> "Services" -> "APIs" -> "API Definitions" -> "Pen" icon next to "arcadia-pub-api"
> Add a policy  
> Policy Type: Authentication  
> Identity Provider: api-protect
> Credential Location apikey: HTTP request header  
> Header name: apikey    
> Save
> Publish

Now in order to check that all is working as expected we will do the following:
1. Run the Postman request "Transfer Money - No Auth". You should receive a 401 message since this request has no api key.
2. Run the Postman request "Transfer Money - With Auth". You should receive a success message and if you go to the main application and refresh the page you will be able to see the trasaction we just did in the "Transfer History" location.


All of our microgateway api configuration is finished. We have published both external and internal APIs and are able to gather and view statistics for traffic coming from external clients and also internally when a service is contacting anther. We have achieved the bellow architecture. 
![](images/6env.jpg)

#### [Next part](7security.md)