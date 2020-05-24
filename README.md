# ReviewAppOperator

Deploy review apps for pull request

## Dev setup

* Install [Virtualbox](https://www.virtualbox.org/wiki/Downloads) to power Minikube
* Install [asdf](https://www.virtualbox.org/wiki/Downloads) to install dev tools and languages
* Run `bin/setup`

### TLS Setup
The setup script will create a one-off root CA whose cert can be found at `dev-resources/tls/ca.crt`. If you want to make sure that portion of the ingress is working properly or just want to view the test review app over TLS, you can add that CA to your trust store. Firefox is a good browser for this because it manages its own trusted CAs rather than making you add them to the operating system.

### Manual Local Testing
1. Start minikube with `minikube start`
1. Start the operator with `bin/console`. (It will run with iex attached.)
1. In another terminal, create a review app with `./bin/dev/create-review-app.sh`
1. This will create a build job as well as the other review app resources, though the deployment will be scaled to 0 until the build finishes.
1. 90s later, the build will finish and the deployment should be scaled up to 1 replica.
1. You should now be able to access your review app at https://test-review-app-678.review.local if you set up the CA certificate in your trust store
1. The test review app shows its environment and tests its DB connection by reading out the "migrations" table in its database. There should be a new migration for every deployment update, with the commit hash as the id.
1. To simulate pushing a new commit to PR number 678, you can run `./bin/dev/patch-review-app.sh`. This will kick off another build.
1. 90s later the second build will finish and the deployment will update. You should be able to see the updated version and new migration in the browser.
1. To kill the review app, run `./bin/dev/delete-review-app.sh`, and all related resources should be cleaned up by the operator.

---

## Requirements / expectations from the Probot side
1. Upload the tarball to S3 (so the operator doesn't need GitHub access)
1. Provide review app config from the repo's yaml file
1. Provide branch, repoOwner, repo, PR # (as a string), commit hash, tarballUrl
1. Update the commitHash, tarballUrl, and review app config when the PR is updated


## Config Requirements
1. Sort out the k8s permissions required and annotate the controller
1. I believe the AWS and Harbor permissions are already in the builder namespace and the same build jobs should work w/o any changes there


## List of resources
- [X] Build job
- [X] app deployment
- [X] app service
- [X] app ingress
- [X] TLS secret for ingress
- [X] app database (kubedb Postgres)
- [X] init secret for app database (to copy from existing db)


## Flow logic breakdown

### build_app
* Delete the existing Job resource, if any
* Create a Job to build the review app
* Update the review app's status info with
  - appStatus: status.appStatus || "building"
  - buildStatus: "building"
  - buildJobName: "build-{SHA}"
  - image: "whatever"
  - buildStartedAt: 1552453453
  - buildCommit: {SHA}


### ADD
* build_app
* Generate the resources and CREATE them, but use a 0 in the deployment replicas
  (The deployment resource builder can do ^ based on the status info on the ReviewApp)


### MODIFY
* Exit if the commitHash == status.buildCommit (b/c we trigger our own events)
* build_app


### RECONCILE
* Exit unless status.buildStatus == "building"
* check the job's status
  * If still building, exit
  * If error
    * set status.buildStatus = "error"
    * just stop
  * If done
    * Update the deployment based on the latest in the ReviewApp, this time with 1 replica and the new image tag
    * Set status.buildStatus = "success"
    * Set status.appStatus = "deployed"

 (I believe this gets called every 30s by default)


### DELETE
Tear down all of the resources, including the current build job specified on the review app
