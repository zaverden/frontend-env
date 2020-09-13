# ENV for frontend

## First, read https://12factor.net/config

It gives you a reason for this repo

NOTE: [build-time VS deploy-time VS runtime](#build-time-vs-deploy-time-vs-runtime)

## Quick start
**Prerequisites**: `docker` 18.06.0+ and `docker-compose` 1.22.0+.

1. Run
    ```shell
    docker-compose up --build
    ```
2. Open `http://localhost:8080` and `http://localhost:8081` in browser
3. Read comments in files

## Short explanation
1. You define your environment in `index.html` following way:
    ```html
    <script>
        const API_BASE_URL = "http://localhost:8080"; // <- default value
        window.$$env = {
            apiBaseUrl: `${API_BASE_URL}`,
        };
    </script>
    ```
2. Run `envsubst` to replace `${API_BASE_URL}` with variable value
    ```shell
    defined_envs=$(printf '${%s} ' $(env | cut -d= -f1))
    envsubst "$defined_envs" < "$template_path" > "$output_path"
    ```
3. All values in `window.$$env` are strings, you need some code to convert them to expected types

## How to, step by step

### index.html

You embed your environment in the `index.html` file. There are few reasons:
1. `index.html` is the (almost) only file in your static site that HAVE to be non-cacheable.
   Or with small cache time. Otherwise, you will have a hard time to roll new version.
   It means that we can update values in `index.html` without problems
2. No extra request. You can put your environment to some `env.js` and add `<script src="./env.js">`
   but it means an extra request on each page load. And cache policy for `env.js` have to be
   the same as for `index.html` - no cache, or short-life cache. Because we want users to get
   updated values ASAP, not after 2 hours ("Have you tried Ctrl+F5?")

You define your environment following way:
```js
const API_BASE_URL = "http://localhost:8080";
window.$$env = {
    apiBaseUrl: `${API_BASE_URL}`,
};
```

`API_BASE_URL` serves as default value for parameter. You just put development values here,
so you don't have to do anything to have it running.

// TODO: what if I want to use my local environment variables in development too?

IMPORTANT: all values in the environment are strings. Actually it is the same way as it works
for backend. You get strings and convert them into expected types, manually or by using some
config packages.


### Dockerfile

You use `nginx` as a base image. If you cannot check [clean environment section](#clean-environment).

An `nginx` image has a good entrypoint. It executes all `*.sh` files from /docker-entrypoint.d
folder on an every start of container. You put script that fills you environment there, and
"it just works"(c).

In this example script name is prefixed with `00-` so it runs first, but in this case it
actually does not matter.

Also you copy `index.html` as `index.html.template`, because at this point it is actually a template,
not a final file.


### 00-envsubst-on-index.html.sh<!---->

Magic happens here 🦄. Except no magic ~~🦄~~.

We want to achieve following:
1. replace if environment variable is provided
2. ignore if environment variable is not provided, so default value from `index.html` is used

An `nginx` image have this already, in [`/docker-entrypoint.d/20-envsubst-on-templates.sh`](https://github.com/nginxinc/docker-nginx/blob/9774b522d4661effea57a1fbf64c883e699ac3ec/mainline/buster/20-envsubst-on-templates.sh).
It does more then you need. If you extract essential lines you end up with:
```shell
defined_envs=$(printf '${%s} ' $(env | cut -d= -f1))
envsubst "$defined_envs" < "$template_path" > "$output_path"
```

## Clean environment

If you don't use docker to serve static files, you still can use this approach. In application
lifecycle starting docker container is the same step as putting files to Amazon S3 - it is deploy step.

I believe now it is clear that you just need to replicate what docker does on container start and
do the same in your deployment procedure. Run
```shell
defined_envs=$(printf '${%s} ' $(env | cut -d= -f1))
envsubst "$defined_envs" < "$template_path" > "$output_path"
```
to convert your `index.html.template` from build artifacts to deployable `index.html`.

[File an issue](https://github.com/zaverden/frontend-env/issues) if you have questions here.

## build-time VS deploy-time VS runtime

**build-time** parameter exists only until build. After build this parameter is replaced with its value
that was set at the moment of build. You cannot change value without rebuild.
Example: [environment variables in webpack](https://webpack.js.org/guides/environment-variables/).

**deploy-time** parameter exists only until deploy. After deploy this parameter is replaced with its value
that was set at the moment of deploy. You cannot change value without redeploy (full or partial).
"Without redeploy" here means you cannot change it without stopping running application.
Example: this repository.

**runtime** parameter always exists. Its value resolves every time you get it (you may cache it for
performance, but main idea does not change). You can change it any time and app will use new value
from next resolving. Example: get config payload from API, watch and reread config file (for backend).

As mentioned above in current repo we use deploy-time parameters. If you want to change them you don't
need to build new version of app from sources, but you should redeploy the app from artifacts:
restart container with new environment variables provided, or run some `deploy.sh` script that
runs `envsubst` on build artifacts and puts final files to Amazon S3 or any other static content server.