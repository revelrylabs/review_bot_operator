### Fake App Image

This code builds a fake app to deploy when testing locally. The images can be built and pushed to a public image repository so your local cluster can easily find them.

For example, if your review app's `repo` is set to `test-review-app` and its `commitHash` begins with `c8c9aa334a7 ` and `pr` number is `678`, then you can build and publish a corresponding stub image with a command like this:

```
docker build -t my-docker-user/test-review-app-678:c8c9aa334a --build-arg VERSION=c8c9aa334a .
docker push my-docker-user/test-review-app-678:c8c9aa334a
```

And set the docker_root configuration to "my-docker-user" to use those images in your review apps.

The stub app shows you its current environment and attempts to read the `migrations` table of the connected POSTGRES database to make sure you have everything wired up. There's also a migrate command at `npm run migrate` that should add another row to the migrations table with the VERSION supplied at build time.
