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

Next we need to perform the installation, to make things easier we created a script you just need to run it in the following way:
<pre>
Commands:
cd controller
npm install
node index --host=18.184.134.91
</pre>

The installation will take around 5 minutes. When done https browse to the IP address of the Controller.
> username: s@s.com  
> password: sorin2019

Next step is to get the API key to connect the microgate way so it is managed by the controller.
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
          image: sorinboia/ngtest:slim
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
> Hostname: https://ae0aa9bf7704745fbb2a47da2c3a2039-258004477.eu-central-1.elb.amazonaws.com  
> Cert Reference: sorin-wild

##### "N" -> "Services" -> "Apps" -> "Create"
> Name: arcadia-app   
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
 NAME           TYPE           CLUSTER-IP      EXTERNAL-IP                                                                 PORT(S)                      AGE
 arcadia-app2   ClusterIP      172.20.23.53    none                                                                        80/TCP                       162m
 arcadia-app3   ClusterIP      172.20.130.68   none                                                                        80/TCP                       162m
 </pre>

We are interested in "app2" and "app3" and their DNS names are "arcadia-app2" and "arcadia-app3".

##### "N" -> "APIs" -> "Workload Groups" -> "Create"
Create the configuration of each of the "Work loads"
> Name: arcadia-app2  
> Click Save  

Add workload
> First input: arcadia-app2  
> Port: 80  

Repeat the steps above for "app3".  
Return to "N" -> "APIs" -> "API Definitions" -> "Pen" Icon -> "Add a published API"
> Published API Name: arcadia-pub-api  
> Environment: prod  
> Application: arcadia-api  
> Gateways: api.arcadia.sorinb.cloud  
> Save  
> Add a route  
> All URLs that start with /api assign work load "arcadia-app2". 
> All URLs that start with /app3 assign work load "arcadia-app3".  
> After adding each route click Save.
> When done click "Publish"

Once the public API has been published we need to take the same procedure and do the same for the internal APIs that are accessing the Arcadia Backend service.  
If you login into the main application at the moment you can observe that the page is broken, this is because we pointed the backend service to go through our microgateway but haven't configured it yet, let's do that now.

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

Now we are going to test our configuration. If you go back to the main app you will able to see that the problems are fixed and you can see the "Transfer History".
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

###### "N" -> "APIs" -> "API Definitions" -> "Pen" icon next to "arcadia-pub-api"
> Add a policy  
> Policy Type: Authentication  
> Identity Provider: api-protect
> Credential Location apikey: HTTP request header  
> Header name: apikey  
> Publish

Now in order to check that all is working as expected we will do the following:
1. Run the Postman request "Transfer Money - No Auth". You should receive a 401 message since this request has no api key.
2. Run the Postman request "Transfer Money - With Auth". You should receive a success message and if you go to the main application and refresh the page you will be able to see the trasaction we just did in the "Transfer History" location.


All of our microgateway api configuration is finished. We have published both external and internal APIs and are able to gather and view statistics for traffic coming from external clients and also internally when a service is contacting anther. We have achieved the bellow architecture. 
![](images/6env.jpg)
