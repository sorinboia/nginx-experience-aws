## Increase availability, security and application performance with Kubernetes Nginx Ingress - part 1

Now we are getting to the interesting part.  
Previously we have deployed the application but did not expose the services.  

We need to be able to route the requests to the relevant service.

Nginx Kubernetes Ingress to save the day! :)

 
##### Lets start with the Nginx deployment.
We are going to use the Nginx installation manifests based on the [Nginx Ingress Controller installation guide](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/).
For simplicity - we have already prepared the installation in a single yaml file.  
Simply run the command bellow.  

<pre>
Command:
kubectl apply -f files/5ingress/nginx-ingress-install.yaml

Output:
namespace/nginx-ingress created
serviceaccount/nginx-ingress created
clusterrole.rbac.authorization.k8s.io/nginx-ingress created
clusterrolebinding.rbac.authorization.k8s.io/nginx-ingress created
secret/default-server-secret created
configmap/nginx-config created
deployment.apps/nginx-ingress created
service/nginx-ingress created
</pre>
  
Next we need to run the following in order to expose the Nginx Dashboard (copy and paste in the command line the bellow).
<pre>
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: dashboard-nginx-ingress
  namespace: nginx-ingress
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp"    
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: nginx-ingress
EOF
</pre>

Lets check that we did so far is actually working. Run the following command:

<pre>
Command:
kubectl get svc --namespace=nginx-ingress

Output:
NAME                      TYPE           CLUSTER-IP      EXTERNAL-IP                                                                 PORT(S)                      AGE
dashboard-nginx-ingress   LoadBalancer   172.20.36.60    aeb592ad4011544219c0bc49581baa13-421891138.eu-central-1.elb.amazonaws.com   80:32044/TCP                 11m
nginx-ingress             LoadBalancer   172.20.14.206   ab21b88fec1f445d98c79398abc2cd5d-961716132.eu-central-1.elb.amazonaws.com   80:30284/TCP,443:31110/TCP   5h35m
</pre>

Note the EXTERNAL-IP of the "dashboard-nginx-ingress". This is the hostname that we are going to use in order to view the Nginx Dashboard.
Browse to the following location and verify that you can see the dashboard: http://<EXTERNAL-IP of "dashboard-nginx-ingress" service>/dashboard.html

Note the EXTERNAL-IP of the "nginx-ingress". This is the hostname that we are going to use in order to publish the Arcadia web application.
Browse to the following location and verify that you receive a 404 status code: http://<EXTERNAL-IP of "nginx-ingress" service>/



##### Now we can get to the interesting part
First we are going to expose all the application services and route traffic based on the HTTP path.
We will start with a basic configuration.
First create a new file, for example arcadia-vs.yaml, add the bellow configuration and apply it:

<pre>
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: arcadia  
spec:
  rules:
  - host: MUST BE REPLACED WITH "EXTERNAL-IP" OF THE "nginx-ingress" SERVICE
    http:
      paths:
      - path: /
        backend:
          serviceName: arcadia-main
          servicePort: 80
      - path: /api/
        backend:
          serviceName: arcadia-app2
          servicePort: 80
      - path: /app3/
        backend:
          serviceName: arcadia-app3
          servicePort: 80
</pre>



At this stage basic install is finished and all is left is to check connectivity to the Arcadia web application, get the public hostname of the exposed Nginx Ingress.  
Browse to the following location and verify that you can access the site: http://<EXTERNAL-IP of "nginx-ingress" service>/


At the moment we still have two key features missing:
1. We are serving only http, no https. We want our site to be fully secured therefor all communication need to be encrypted.
2. We are not actively monitoring the health of the pods through the data path


First take a look at the files/5ingress/2arcadia.yaml file. It increases the number of pod to two of our services service and also defines how the http health checks will looks like.
Lets apply this new configuration.
<pre>
Command:
kubectl apply -f files/5ingress/2arcadia.yaml
</pre>

If you look at the Nginx dashboard you can see that right now that two HTTP upstreams have 2 members but no health checks are being done.  
In our next step we will finish this part of the configuration, we will implement the following:  
- Enable health checks
- Enable https for the application and redirect http requests to https

Create ingress-arcadia.yaml to reflect the bellow and apply the configuration.
<pre>
apiVersion: v1
kind: Secret
metadata:
  name: arcadia-tls
  namespace: default
data:
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUZWRENDQkR5Z0F3SUJBZ0lTQTZmZXlEYXhUUFc4eFdlLys2K1h0eUhOTUEwR0NTcUdTSWIzRFFFQkN3VUEKTUVveEN6QUpCZ05WQkFZVEFsVlRNUll3RkFZRFZRUUtFdzFNWlhRbmN5QkZibU55ZVhCME1TTXdJUVlEVlFRRApFeHBNWlhRbmN5QkZibU55ZVhCMElFRjFkR2h2Y21sMGVTQllNekFlRncweU1EQTBNVGd4TURJNU1qUmFGdzB5Ck1EQTNNVGN4TURJNU1qUmFNQmt4RnpBVkJnTlZCQU1NRGlvdWMyOXlhVzVpTG1Oc2IzVmtNSUlCSWpBTkJna3EKaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUFtLzI0WDZpb0gybWhWUjJSQlhCQXd1KzlFMkxTZldMRwpldEtJbU1RdTN2Mzh5NDZJbnZubmpDNis1VDFqdk1INEVIY1Bmcy9qUS8zbDRjUWtiRWhQYUEwVXluRmEwbEUvClNidmJmbVdsOUlBZmc0eXc0cWxmTW5GNFdXVEFWQlhwVDhpZFZnc2tQaDVuMVdQUDdBSVJxNXFhUkR3YWVZMUEKOE5VREY1T3RsYXNvYitxdTBOTnJnSUZvQ0ZVODQ4cUJEWllLODhXalYyQStxVG5xSko0U3ZoMFNOUDBYWmRoQgo2TkRKT3RBWDlYbWdybTlxWFBFMXE0QU0yazNTNFllb1ZvRWNnQnRMdTRocWRxMlhhQWhOc1RHcVYzaXgvNkhFCjRFMU5iMElEdmxGdHlhVFl6ZXhTRHRKOGx4OEIwa0Jwa2xoaG93MjBQS3R2NjhkOUE0TGc5UUlEQVFBQm80SUMKWXpDQ0FsOHdEZ1lEVlIwUEFRSC9CQVFEQWdXZ01CMEdBMVVkSlFRV01CUUdDQ3NHQVFVRkJ3TUJCZ2dyQmdFRgpCUWNEQWpBTUJnTlZIUk1CQWY4RUFqQUFNQjBHQTFVZERnUVdCQlFaS3M4Q1FJRmd6NWFQQXJKWE13aDVhNW4yCkR6QWZCZ05WSFNNRUdEQVdnQlNvU21wakJIM2R1dWJST2JlbVJXWHY4Nmpzb1RCdkJnZ3JCZ0VGQlFjQkFRUmoKTUdFd0xnWUlLd1lCQlFVSE1BR0dJbWgwZEhBNkx5OXZZM053TG1sdWRDMTRNeTVzWlhSelpXNWpjbmx3ZEM1dgpjbWN3THdZSUt3WUJCUVVITUFLR0kyaDBkSEE2THk5alpYSjBMbWx1ZEMxNE15NXNaWFJ6Wlc1amNubHdkQzV2CmNtY3ZNQmtHQTFVZEVRUVNNQkNDRGlvdWMyOXlhVzVpTG1Oc2IzVmtNRXdHQTFVZElBUkZNRU13Q0FZR1o0RU0KQVFJQk1EY0dDeXNHQVFRQmd0OFRBUUVCTUNnd0pnWUlLd1lCQlFVSEFnRVdHbWgwZEhBNkx5OWpjSE11YkdWMApjMlZ1WTNKNWNIUXViM0puTUlJQkJBWUtLd1lCQkFIV2VRSUVBZ1NCOVFTQjhnRHdBSFlBc2g0RnpJdWl6WW9nClRvZG0rU3U1aWlVZ1oydmErbkRuc2tsVExlK0xrRjRBQUFGeGpRemx3UUFBQkFNQVJ6QkZBaUFLdDdienBvcEcKUjd6MFNFajdES0xxUjFoTFhMVElrZWJkNEFqaE04dHg4UUloQUxXNTFJVFd2WFMyV09DZkRUcEF2WWFZaEMyVApyWlM5K1ZtTzBLL0dsMnBuQUhZQWIxTjJyREh3TVJuWW1RQ2tVUlgvZHhVY0Vka0N3UUFwQm8yeUNKbzMyUk1BCkFBRnhqUXptaWdBQUJBTUFSekJGQWlCejZxbWF4UDNlWTVNOHh4S0hsL25nTlhsNU40SlhHdXhZNGFEY1BqNW4KZVFJaEFJNzMwd2oxS3BwbXRTOXhkb3JOdTdTaGJROGVFZFhXZXF2SnRrWVMvVlgyTUEwR0NTcUdTSWIzRFFFQgpDd1VBQTRJQkFRQTZiQkR4ZUVyaXJ3NmNTK2RwVGV5dVo4bTZsbWUyMmxrN3dMaENtUlJWL25LMURVVGJVdlFWCitEK290ZjlNTEU0TjZMUll5RTlVeHZrTTc2SkVpMHpLVjdEKzhuaUI5SkV1ZTFqL1dwcTJSdXZwRnVmYTVUZVgKL01pVXJNU2tXc0Q3dkx4MWNqdHhoa2FCZk1GUUd6ek9ma0FialBRdTRQTk1tNW03bWdHV1pTT0VxQTNQVE5XSwpuUzZSTEtTSjlIWUZuZ3MzTFhleERzTTNNd1d3TmJyMktJNUFPU3oyellYbzN2Uzh5Y25rWDU2QzJTOEYvaGRSCjVmVUsxZXdHN1RHTk9rRmhKckQwTUhYbzR4c28rVXRCY0k1Z3lHVFcwM3dwMmNTVHcraFhrczQyVUJVS3BIQkgKSjlHQkY5SDRJUXV3aHAyalZzR1pXRVBYelg2R2lVYzAKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
  tls.key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2d0lCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktrd2dnU2xBZ0VBQW9JQkFRQ2IvYmhmcUtnZmFhRlYKSFpFRmNFREM3NzBUWXRKOVlzWjYwb2lZeEM3ZS9mekxqb2llK2VlTUxyN2xQV084d2ZnUWR3OSt6K05EL2VYaAp4Q1JzU0U5b0RSVEtjVnJTVVQ5SnU5dCtaYVgwZ0IrRGpMRGlxVjh5Y1hoWlpNQlVGZWxQeUoxV0N5UStIbWZWClk4L3NBaEdybXBwRVBCcDVqVUR3MVFNWGs2MlZxeWh2NnE3UTAydUFnV2dJVlR6anlvRU5sZ3J6eGFOWFlENnAKT2Vva25oSytIUkkwL1JkbDJFSG8wTWs2MEJmMWVhQ3ViMnBjOFRXcmdBemFUZExoaDZoV2dSeUFHMHU3aUdwMgpyWmRvQ0UyeE1hcFhlTEgvb2NUZ1RVMXZRZ08rVVczSnBOak43RklPMG55WEh3SFNRR21TV0dHakRiUThxMi9yCngzMERndUQxQWdNQkFBRUNnZ0VBQnFJMGpBVGRHWERoaG9BYVliUFRYVGJhd0k5TVNqN0FHQXNKK2cwbHZSL3AKOXpJWmgwRXpZcGUrVUh0YTJYVWFPb0VGckt2a2kwaXAxUDhGV1lGOXR2d1BiVWlDeHp6alJ4eHhDaUFDZmJKUgpKTVAvNWJPME02MzFveitRbWtMUVNDOU0yWkxodUs2TVZkdkh4TTZWdDhsOFUvaUdXN0x4Rnd6SDgrRzQyUXQ4ClRCeDUzUWdDZGgxcDVFNC9sSFNzUmdIRlRRbUZXWmE0M3NkVlA1VUs4VHhtcElpdXBid0JrUG1TQ2JDUXoxM0YKTlRGQSs2aXIrQjdETzJUaGxJMytXNEdoYVdPaXBUYk5xTGFMR2xXOEhrZFhzRFlDRXRHRFRnWEtVSDBBUFZzTgpUTnYxYkhTS0hhc1UwejlaNk5IdmU1THdPK214K1RYUE42bXRURURnUlFLQmdRRE96R1B1TGd4a1dwYWxHNDRHClJhcHhqa1pUMnNRbjdWa1IzMXQveElOZGNIV3JZMG8xaWxpYVdBdDA5NDhmUGJKT3JCOFNSdDVkTGN3MlBzMUwKR2UyQTUxUFlpeTRGVkR6S3laSmNqMFczMEVZMG5kSWM5UHh3ME1oMUtqZndJTEJJTlFaSDBJQWtiWC9GU0EyYQpOaWVXRDNiL000NklGUTl5eFlIY1JLeGEvd0tCZ1FEQkdzWnBEU2hCMVFFVTRxbEhkRTdXOGFxM0hZWG15RnRGCm9xREhQNmNiUEtFVEpTcEc4NWkwRHo0ZUMxbTUvTFZiR3lvR1FGdlFEem03Q1ZtdGxYMExSOTBzNWpuSmZwWGEKc1FtY1VPdmc3RVI0YmhUM1FDUzRVUy9CamsrTFJTVnpIVWFpbG94ZDdVVGtlS21BbEI2dFdEaVNsTXZod3NXKwpYbjg1Z2IwSUN3S0JnUUNzYTNtK01xS2VZWEZOQkNac1VGV0dER3ZTcW9uMkNFekZQQWRjQmdySk0yVElteVphCmNaamlSeHAyVVpvQklEMjBub25oZ1RrUlU0ZjZpbTQ4ZWNldVBER0tVTEQwUElIYlNpbEFCeXpIejExWnJXUnMKUkU3ZCtSWEpxb090TUhRS0lEdTJVTDhtb0MxeDNWdUtBakVMU3FXYXJlL2V3a0I1SHZmaElWamJIUUtCZ1FDcgovdkk4ZllpZTRsODlRQW53NkFxVTd0blVrZ3BESGJBV0hSMUJlMU9YTWZCeVFnY2UvVGZGSVZKOXBqUjhNVGRECmQ3VjlyZk5aSlVhUmJtbWU3K2habE4vT2J4MkhlQ1YzalhwMjdhaTdSUlpUZ2hGUWpLUm9PMy9pMGFQTjgzL0EKd1pHNW5ZaFczTkFoQTh4T0J5QXYyOFUvNGlLYTZrWUJJdUFFMDZjUU13S0JnUUNMYTBSaHV5MEl1T2k5djBacgpwTjdWd1FaK2JwVWhBQmtXaEg5SGJWTndpclYvaTZBWElTT2JFbjRZdU1zN2w2ZkhCdDJDSlVicENlM2JCUS9nCjdCMG9VR0xMMVdOOG0xVHlKaWhXaC9WZk5sMUlNTTJEZkc3L1FpaFNKZWUxaW04RnlVZUx4TGVjYnllUmZHRDMKUXlTMlVIL2orYnZOYStMekF3SmJTNmN0UkE9PQotLS0tLUVORCBQUklWQVRFIEtFWS0tLS0tCg==
type: kubernetes.io/tls

---

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: arcadia
  annotations:
    nginx.com/health-checks: "true"
    ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - MUST BE REPLACED WITH "EXTERNAL-IP" OF THE "nginx-ingress" SERVICE
    secretName: arcadia-tls
  rules:
  - host: MUST BE REPLACED WITH "EXTERNAL-IP" OF THE "nginx-ingress" SERVICE
    http:
      paths:
      - path: /
        backend:
          serviceName: arcadia-main
          servicePort: 80
      - path: /api/
        backend:
          serviceName: arcadia-app2
          servicePort: 80
      - path: /app3/
        backend:
          serviceName: arcadia-app3
          servicePort: 80
</pre>

Now when you try to browse to the Arcadia website with http you will be automatically redirected to https.  
Second if you look at the Nginx dashboard you can observe that Nginx has started monitoring the pods.

Our next step in the application journey will be to speed up application performance and enable caching.  
Create a new file nginx-config.yaml that reflects the bellow configuration and apply it. We are telling Nginx to create a caching entity that will be used by our Ingress.
<pre>
kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-config
  namespace: nginx-ingress
data:
  proxy-protocol: "True"
  real-ip-header: "proxy_protocol"
  set-real-ip-from: "0.0.0.0/0"
  http-snippets  : |
    proxy_cache_path /var/tmp/a levels=1:2 keys_zone=my_cache:10m max_size=100m inactive=60m use_temp_path=off;
</pre>

Next we will tell our Nginx Ingress to start using it and start caching:
<pre>
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: arcadia
  annotations:
    nginx.com/health-checks: "true"
    ingress.kubernetes.io/ssl-redirect: "true"
    nginx.org/server-snippets: |
      proxy_ignore_headers X-Accel-Expires Expires Cache-Control;
      proxy_cache_valid any 30s;
    nginx.org/location-snippets: |      
      proxy_cache my_cache;
      add_header X-Cache-Status $upstream_cache_status;

spec:
  tls:
  - hosts:
    - MUST BE REPLACED WITH "EXTERNAL-IP" OF THE "nginx-ingress" SERVICE
    secretName: arcadia-tls
  rules:
  - host: MUST BE REPLACED WITH "EXTERNAL-IP" OF THE "nginx-ingress" SERVICE
    http:
      paths:
      - path: /
        backend:
          serviceName: arcadia-main
          servicePort: 80
      - path: /api/
        backend:
          serviceName: arcadia-app2
          servicePort: 80
      - path: /app3/
        backend:
          serviceName: arcadia-app3
          servicePort: 80
</pre>

We have two simple indicators to check that all is working:  
- First if we open the browser developer tools we can see a new http header in the response called "X-Cache-Status".  
If the response was taken from the cache it will have a value of "HIT" otherwise if it was server by the server the value will be "MISS"
- The second options is to look at the Nginx Dashboard -> Caches and observe the HIT ration and traffic served

#### [Second part](5ingress1.md)  
