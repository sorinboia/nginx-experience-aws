## Security

For our final part of the lab we will implement a per-pod Web Application Firewall. The Nginx Waf will allow to increase application security especially for [OWASP Top 10 attacks](https://owasp.org/www-project-top-ten/).  
In our scenario since we decided our Nginx Waf to be enabled on a per pod basis we are able to protect all of the traffic coming into the pod regardless of where is it originated from ( external or internal to the Kubernetes cluster).  
We are able to bring security closer to the application and the development cycle and integrated into CI/CD pipelines. This will allow the almost remove false positives since it becomes a part of the application and is always tested as such.  

First we will start by applying the Nginx Waf config which can be found in the "files/7waf/waf-config.yaml".  
<pre>
Command:
kubectl apply -f files/7waf/waf-config.yaml
</pre>

The Waf policy is json based and from the example bellow you can observe how all the configuration can be changed per application needs.
<pre>
    {
      "name": "nginx-policy",
      "template": { "name": "POLICY_TEMPLATE_NGINX_BASE" },
      "applicationLanguage": "utf-8",
      "enforcementMode": "blocking",
      "signature-sets": [
      {
          "name": "All Signatures",
          "block": false,
          "alarm": true
      },
      {
          "name": "High Accuracy Signatures",
          "block": true,
          "alarm": true
      }
    ],
      "blocking-settings": {
      "violations": [
          {
              "name": "VIOL_RATING_NEED_EXAMINATION",
              "alarm": true,
              "block": true
          },
          {
              "name": "VIOL_HTTP_PROTOCOL",
              "alarm": true,
              "block": true,
              "learn": true
          },
          {
              "name": "VIOL_FILETYPE",
              "alarm": true,
              "block": true,
              "learn": true
          },
          {
              "name": "VIOL_COOKIE_MALFORMED",
              "alarm": true,
              "block": false,
              "learn": false
          }
      ],
          "http-protocols": [{
          "description": "Body in GET or HEAD requests",
          "enabled": true,
          "learn": true,
          "maxHeaders": 20,
          "maxParams": 500
      }],
          "filetypes": [
          {
              "name": "*",
              "type": "wildcard",
              "allowed": true,
              "responseCheck": true
          }
      ],
          "data-guard": {
          "enabled": true,
              "maskData": true,
              "creditCardNumbers": true,
              "usSocialSecurityNumbers": true
      },
      "cookies": [
          {
              "name": "*",
              "type": "wildcard",
              "accessibleOnlyThroughTheHttpProtocol": true,
              "attackSignaturesCheck": true,
              "insertSameSiteAttribute": "strict"
          }
      ],
          "evasions": [{
          "description": "%u decoding",
          "enabled": true,
          "learn": false,
          "maxDecodingPasses": 2
      }]}
    }
</pre>

First thing we will do is prepare ELK in order for us to be able to visualize and analyze all of the traffic going through the Nginx Waf.
<pre>
Command:
kubectl apply -f files/7waf/elk.yaml
</pre>

In order to connect to our ELK instance we will need to find the public address of this service.
<pre>
Command:
kubectl get svc elk-web

Output:
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP                                                                  PORT(S)                                        AGE
elk-web   LoadBalancer   172.20.179.34   a28bd2d8c94214ae0b512274daa06211-2103709514.eu-central-1.elb.amazonaws.com   5601:32471/TCP,9200:32589/TCP,5044:31876/TCP   16h
</pre>

Wait a minute or two and verify that ELK is up and running by browsing to: http://[YOUR EXTERNAL IP]:5601 .

Next we need to change our deployment configuration so it includes the Nginx Waf.
<pre>
Commands:
kubectl apply -f files/7waf/arcadia-main.yaml
kubectl apply -f files/7waf/arcadia-app2.yaml
kubectl apply -f files/7waf/arcadia-app3.yaml
kubectl apply -f files/7waf/arcadia-backend.yaml
</pre>

Right now all of our services are monitored and protected.  
First browse again to the Arcadia web app and verify that it is still working.  
After that lets do an attack and verify that it is blocked by doing a Cross Site Scripting attack. Do a few of these requests
> https://<YOUR IP/HOSTNAME>/trading/index.php?a=%3Cscript%3Ealert(%27xss%27)%3C/script%3E

On each of the blocked requests you have received a support ID, save it for later.  
Browse to ELK as before and click the "Discover" button:  

![](images/kibana1.JPG)  

You will see all of the request logs,good and bad, sent by Nginx Waf to ELK.
Lets look for the reason why our bad requests were blocked, add a filter with the support ID you have received as seen bellow.
  
![](images/kibana2.JPG)  

In the right side of the panel you can see the request log and the reason why it was blocked.
Continue and explore the visualization capabilities of Kibana while receiving the relevant log information from Nginx Waf by looking into the next two buttons bellow the "Discover" button.

![](images/7env.JPG)

### THE END
### Hope you have enjoyed the workshop.

