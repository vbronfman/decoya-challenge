# Description
The project implements requirements to create Web page to show:

  - current local date and time
  - name of the current machine.
  
  ## NOTE  
  Then it comes to this one, my assamption is name of the host aka k8s pod the site runs upon.
  In case, it should be name of client host from which deployment is done - there is slightly different implemention tested with use of the "Configmap" attached as volume to container. I tested it manually, but didn't include in current terraform manifest.


# Implementation

## Docker image

The docker image is built with docker client by means of ./Dockerfile.

The customisations are done:

- custom index.html to run business logic

- Turns out there is a need to tweek nginx that comes out apk package of nginx. Namely, file /etc/nginx/http.d/default.conf overridden with custom version.

- root set to _/var/www/html_

- Due to container to run as non-root user there is a need to grant access to files of nginx. For the same, it turns out there is no way to bind port 80 as non-root, so default set 8080.


## index.html

Required functionality are rendered within JavaScript of the page.

- time is done with Date() function .

- then it comes to explore content of the file, turns out (who would have beleive it?.. ) that JS runs in sandbox and has no aceess to whatsoever resources of local host. 

The trick that works is to fetch the machine name from the '__filetoreadfrom__' file inspired by https://dev.to/ramonak/javascript-how-to-access-the-return-value-of-a-promise-object-1bck

The solution renders an ability to read file from the location relative to 'root'. So  the way is to have a file in well-known  location aka hardcoded with the content is populated upon container's start.  


## terraform manifests
Terraform project creates:
 - new namespace, default name is "decoya-assignment"
 - deployment to run workload, default num of replics is 1
 - NodePort service listens port 80
 - Ingress of class NGINX

Ddeployment spec consists of init container and regular one. Both have emptyDir volume to share data. 

Init container populates name of the pod into file of well-known location: __/var/www/html/filetoreadfrom__

## The test script
For simplicity sake the project makes no use of proper Python testing frameworks and approaches like pytest. as a substitute the script runs  over data upon web page straightforwardly.

The project employs Selenium framework to test dynamic content of page.
Python script performs following test:

  - ID of element ot represent date is exists and not empty
  - value of 'date' in text is equil to current date 
  - Test to verify the name of host are appears on the page conforms to names of k8s pods. As a matter of fact, the test has been created before it figured out that it was not required :(

# BUILD 

## Prerequisits
1. Git client 
2. Docker client or compatible tool to build docker image. 
3. Access to docker hub to push image
4. Terraform client
5. Kubernetes cluster available, kubectl configuration properly set in ~/.kube/config.
6. Python3 and access to public PIP repo.

## CLONE
Files of the project are located in Github. To start with the project do fetch and expend it with git:

_git clone https://github.com/vbronfman/decoya-challenge.git_

_cd decoya-challenge_


## DOCKER IMAGE
In case of need to build new image - follow below instructions. Otheerwise proceed to DEPLOYMENT section

1. Build image with :
_docker build -t vladbronfman/decoya-assignment -f Dockerfile ._

2. Tag image in case of use docker registry other then _vladbronfman_
> $ docker tag my-nginx-image:latest vladbronfman/decoya-assignment

3. Login to docker hub (or repo of your choice).
_docker login_

4. Upload image to repo:
> $  _docker push vladbronfman/decoya-assignment_
 

## Deploy into k8s cluster with terraform
The tool of choice is Terraform. 

For agility sake the project employs connection to k8s cluster by means of kubeconfig file. The client should be equiped with properly set ~/.kube/config  

_terraform init_

_terraform plan_

_terraform apply -auto-approve_


To provide custom values replace 

_terraform apply -auto-approve --var namespaceifany="new namespace"_ \
                _--var numofreplicas=<default 1>_  \
                _--var imagename=<name of image to run nginx>_ 


## Install test environment  
1. Install required modules:

_pip install selenium,datetime,re_

_pip install kubernetes_

or 

_python3 -m pip install selenium,selenium,datetime,re_

_python3 -m pip install kubernetes_

2. Run script __site-scrapper.py__ :
   
_python3 site-scrapper.py_

## Usage:
Usage: site-scrapper.py [-h] [-u URL] [-n NAMESPACE]

options:

  -h, --help            show this help message and exit
  
  -u URL, --url URL     URL to test. default is http://localhost/
  
  -n NAMESPACE, --namespace NAMESPACE k8s namespaces to search for corresponding resources. Default is decoya-assignment

### Example:
        python3 site-scrapper.py -u http://pcbang/

### Output:
The script uses logger for output. Debug output redirected to debug.log in current folder. "INFO" is printed to terminal:

__Results:__

__checkDatetime : PASSED__

__checkHostnameifany : PASSED__

## Removal of deployment
_terraform destroy_


# References
https://dev.to/ramonak/javascript-how-to-access-the-return-value-of-a-promise-object-1bck

https://pythonexamples.org/python-selenium-get-div-with-specific-id/
https://www.zenrows.com/blog/scraping-javascript-rendered-web-pages
https://www.browserstack.com/guide/python-selenium-to-run-web-automation-test 
