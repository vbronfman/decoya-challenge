
COPY  index.html /var/www/html
#  /etc/nginx/http.d/default.conf have to substitute with custom or edit location / to add:


/etc/nginx/http.d/default.conf:
   # This is a default site configuration which will simply return 404, preventing
# chance access to any other virtualhost.

server {
        listen 80 default_server;
        listen [::]:80 default_server;

        # Everything is a 404
        location / {
#               return 404;
        root /var/www/html ;
        index index.html ;
        }

        # You may need this to prevent return 404 recursion.
        location = /404.html {
                internal;
        }
}


## BUILD 
docker build -t vladbronfman/my-nginx-image -f Dockerfile .

root_admin@PCBANG:/mnt/d/Develop/decoya-challenge$ docker tag my-nginx-image:latest vladbronfman/decoya-assignment
docker login 
root_admin@PCBANG:/mnt/d/Develop/decoya-challenge$ docker push vladbronfman/decoya-assignment
 
docker start -d --name decoya-assignment -env FILETOREAD=/tmp/filetoreadfrom -p 80:80 my-nginx-image
and
cat <(hostname --fqdn) | docker exec -i  e31e56f6a13c362bb6cb7218ccc4bd2932a0d718ade64a017200370b200c8058  sh -c "cat > ${FILETOREADFROM}"

or
envvar doesnt work - going to use hardcode
FILETOREAD=/tmp/filetoreadfrom docker run -d --name decoya-assignment --env FILETOREAD=${FILETOREAD}  --mount type=bind,source=/etc/hostname,target=${FILETOREAD},readonly --restart=unless-stopped -p 8080:8080 vladbronfman/decoya-assignment:latest 
# in this case content of the file in the container  isn't updated upon change of /etc/hostname at docker host.
# the solution is to mount the entire folder of /etc


# DEPLOYMENT
The tool of choice is Terraform. 

For agility sake the project employs connection to k8s cluster by means of kubeconfig file. The client should be equiped with properly set ~/.kube/config  



## Kubernetes 


 kubectl create configmap myconfig --from-literal=filetoreadfrom=pcbang

 kubectl expose po decoya-assignment

https://aperogeek.fr/kubernetes-deployment-with-terraform/ 

root_admin@PCBANG:/mnt/d/Develop/decoya-challenge$ kubectl port-forward -n decoya-assignment service/decoya-assignment-svc 3777:80

## Deploy into k8s cluster with terraform


git clone https://github.com/vbronfman/decoya-challenge.git
git cd decoya-challenge

terraform init
terraform apply 



# TESTING
For simplicity sake the project makes no use of proper Python testing frameworks and approaches like pytest. as a substitute the script runs  over data upon web page straightforwardly.

The project employs Selenium framework to test dynamic content of page.
Python script performs followinf test:

  - ID of element ot represent date is exists and not empty
  - value of 'date' in text is equil to current date 
  - Test to verify the name of host are appears on the page conforms to names of k8s pods. As a matter of fact, the test has been created before it figured out that it was not required :(

## Install test environment
Script makes use of modules:

_pip install selenium,datetime,re_
_pip install kubernetes_
or 
_python3 -m pip install selenium,selenium,datetime,re_
_python3 -m pip install kubernetes_


## Usage:
Usage: site-scrapper.py [-h] [-u URL] [-n NAMESPACE]

options:
  -h, --help            show this help message and exit
  -u URL, --url URL     URL to test. default is http://localhost/
  -n NAMESPACE, --namespace NAMESPACE
                        k8s namespaces to search for corresponding resources. Default is decoya-assignment

### Example:
        python3 site-scrapper.py -u http://pcbang/

### Output:
The script uses logger for output. Debug output redirected to debug.log in current folder. "INFO" is printed to terminal:

__Results:__
__checkDatetime : PASSED__
__checkHostnameifany : PASSED__


## References
https://pythonexamples.org/python-selenium-get-div-with-specific-id/
https://www.zenrows.com/blog/scraping-javascript-rendered-web-pages
https://www.browserstack.com/guide/python-selenium-to-run-web-automation-test !!

