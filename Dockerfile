# Use Alpine Linux as the base image
FROM alpine:latest

# Install Nginx and some other necessary packages
RUN apk --no-cache add nginx

# Create a non-root user for Nginx
#RUN adduser -D -H -s /sbin/nologin nginx

# Set file ownership to the non-root user
RUN chown -R nginx:nginx /var/lib/nginx

RUN chown -R nginx:nginx /var/www

# Copy a custom Nginx configuration file (if needed)
# COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /var/www/html/index.html    

#turns out /etc/nginx/http.d/default.conf out the box screens out /index.html
#going to overrride with custom one

COPY <<EOF /etc/nginx/http.d/default.conf
server {
# for the container run with non-root it can not listen ports under 1024; set 8080
	listen 8080 default_server;
	listen [::]:8080 default_server;
        root /var/www/html ;
        index index.html ;

	# Everything is a 404
#	location / {
#		return 404;
#	}

	# You may need this to prevent return 404 recursion.
	location = /404.html {
		internal;
	}
}

EOF

#COPY /etc/nginx/http.d/localhost.conf or /etc/nginx/http.d/default.conf
# Create a directory for Nginx's run directory
RUN mkdir -p /run/nginx

# Expose Nginx's default HTTP port
EXPOSE 8080

# Set Nginx as the default process to run when the container starts, running as the non-root user
USER nginx
CMD ["nginx", "-g", "daemon off;"]

