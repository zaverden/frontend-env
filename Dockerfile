# Pin exact version to have repeatable builds (see more https://12factor.net/dependencies)
FROM nginx:1.19.2

# entry point from nginx image executes all *.sh files
# from /docker-entrypoint.d folder on every start of container
COPY 00-envsubst-on-index.html.sh /docker-entrypoint.d

# we save index.html as index.html.template
COPY ./index.html /usr/share/nginx/html/index.html.template
