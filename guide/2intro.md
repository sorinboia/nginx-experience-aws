## Intro to the workshop

This workshop will provide guidelines on how to deploy an application from scratch in Amazon Elastic Kubernetes Service environment while protecting and enhancing the application availability and usability with Nginx solutions.

For this workshop we are going to use the "Arcadia Financial" application.
The application is built with 4 different microservices that are deployed in the Kubernetes environment.
- Main - provides access to the web GUI of the application for use by browsers
- Backend - is a supporting microservice and provides support for the customer facing services only
- App2 - provides money transfer API based functionalities for both the Web app and third party consumer applications
- App3 - provides referral API based functionalities for both the Web app and third party consumer applications



By the end of the workshop the "Arcadia Financial" will be fully deployed and protected as described in the bellow diagram.

![](images/2env.jpg)


### Login to AWS Workshop Portal

This workshop creates an AWS account and a Cloud9 environment. You will need the **Participant Hash** provided upon entry, and your email address to track your unique session.

Connect to the portal by clicking the button or browsing to [https://dashboard.eventengine.run/](https://dashboard.eventengine.run/). The following screen shows up.

![Event Engine](/images/event-engine-initial-screen.png)

Enter the provided hash in the text box. The button on the bottom right corner changes to **Accept Terms & Login**. Click on that button to continue.

![Event Engine Dashboard](/images/event-engine-dashboard.png)

Click on **AWS Console** on dashboard.

![Event Engine AWS Console](/images/event-engine-aws-console.png)

Take the defaults and click on **Open AWS Console**. This will open AWS Console in a new browser tab.

Once you have completed the step above, you can head straight to [**Create a Workspace**](/020_prerequisites/workspace/)





Now, lets start and clone the git repository that will help us during the workshop.

> git clone https://github.com/sorinboia/nginx-experience-aws


#### [Next part](3tf.md)
