## Increase availability, security and application performance with Kubernetes Nginx Ingress - part 1

Now we are getting to the interesting part.  
Previously we have deployed the application but was able to expose only the Main service.  
This is due to the fact that the application accesses the additional features through the same exposed IP:port which was currently routed to only the Main service.

We need to be able and understand the requests and send them to the relevant service.

Nginx Kubernetes Ingress to save the day :).

 
#####Let start by doing the Nginx deployment.
We are going to use Nginx installation with manifests following the step by step instructions on the Nginx site.  
[https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/)   

Follow the instructions and stop after finishing the second stage.
To be able and use the full Nginx capabilities we are going to use Nginx Plus.  
Nginx Plus requires you to build your own container prior to the deployment, we need to change the location the container image is pulled from.  
Edit the file at "deployment/nginx-plus-ingress.yaml", instead of:
<pre>
- image: nginx-plus-ingress:1.6.3
</pre>

It should look like this:
<pre>
- image: sorinboia/nginx-plus-ingress:edge
</pre>
Save the file and continue with the instructions in the Nginx installation guide. We are doing to deploy Nginx Ingress as a "Deployment" not a "DeamonSet".

At this stage basic install is finished and all is left is to check connectivity, get the public hostname of the exposed Nginx Ingress.

<pre>
Command:
kubectl get svc nginx-ingress --namespace=nginx-ingress

Output:
NAME            TYPE           CLUSTER-IP      EXTERNAL-IP                                                                 PORT(S)                      AGE  
nginx-ingress   LoadBalancer   172.20.202.34   a8002804ddc6f4cc19938b35d423384d-412080330.eu-central-1.elb.amazonaws.com   80:32160/TCP,443:30997/TCP   10m
</pre>

Use the "EXTERNAL-IP" and check both http and https access. In both cases you should get a 404 Not Found error since the traffic is not routed.

##### Now we can get to the interesting part
First we are going to expose all the application services and route traffic based on the HTTP path.
We will start with a basic configuration.
First create a new file, for example arcadia-vs.yaml and add the bellow configuration:

<pre>
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: arcadia  
spec:
  rules:
  - host: a8002804ddc6f4cc19938b35d423384d-412080330.eu-central-1.elb.amazonaws.com
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

Now you can browse to the application and verify that it is working.
At the moment we still have two key features missing:
1. We are serving only http, no https. We want our site to be fully secured therefor all communication need to be encrypted.
2. We are not actively monitoring the health of the pods through the data path


First take a look at the 2arcadia.yaml file. It increases the number of pod to 2 for each service and also defines how the http health checks will looks like.
Lets apply this new configuration.
<pre>
Command:
kubectl apply -f 2arcadia.yaml
</pre>

If you look at the Nginx dashboard you can see that right now each upstream has 2 members but no health checks are being done.  
In our next step we will finish this part of the configuration, we will implement the following:  
- Enable health checks
- Enable https for the application and redirect http requests to https

Change the ingress-arcadia.yaml to reflect the bellow and apply the configuration.
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
    - a8002804ddc6f4cc19938b35d423384d-412080330.eu-central-1.elb.amazonaws.com
    secretName: arcadia-tls
  rules:
  - host: a8002804ddc6f4cc19938b35d423384d-412080330.eu-central-1.elb.amazonaws.com
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
First lets make sure that nginx-config.yaml reflects the bellow configuration. We are telling Nginx to create a caching entity that will be used by our Ingress.
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
    - a8002804ddc6f4cc19938b35d423384d-412080330.eu-central-1.elb.amazonaws.com
    secretName: arcadia-tls
  rules:
  - host: a8002804ddc6f4cc19938b35d423384d-412080330.eu-central-1.elb.amazonaws.com
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