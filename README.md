
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


Kubernetes 
What does it mean "current machine name"?
create configmap

 kubectl create configmap myconfig --from-literal=filetoreadfrom=pcbang

 kubectl expose po decoya-assignment

https://aperogeek.fr/kubernetes-deployment-with-terraform/ 

root_admin@PCBANG:/mnt/d/Develop/decoya-challenge$ kubectl port-forward -n decoya-assignment service/decoya-assignment-svc 3777:80


TESTING

https://www.zenrows.com/blog/scraping-javascript-rendered-web-pages
