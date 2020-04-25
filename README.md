# ReviewAppOperator

Deploy review apps for pull request


### build_app
* Create a Job to build the review app
* Update the review app's status info with
  - appStatus: status.appStatus || "building"
  - buildStatus: "building"
  - jobName: "build-{SHA}"
  - latestImageTag: "whatever"
  - startedAt: 1552453453
  - lastCommit: {SHA}


### ADD
* build_app
* Generate the resources and CREATE them, but use a 0 in the deployment replicas


### MODIFY
* If the commitHash == status.lastCommit, ignore (in case we trigger our own events)
* If status.buildStatus == "building" kill the existing job (optional)
* build_app


### RECONCILE
* If status.buildStatus != "building", exit
* check the job's status
  * If still building, exit
  * If error
    * set status.buildStatus = "error"
    * run DELETE action
  * If done
    * Update the deployment based on the latest in the ReviewApp, this time with 1 replica and the new image tag
    * Set status.buildStatus = "done"
    * Set status.appStatus = "deployed"

 (I believe this gets called every 30s by default)


### DELETE
Tear down all of the resources, including all build jobs associated with this review app


### Requirements from the Probot side
1. Provide review app config from the repo's yaml file
1. Provide branch, repo, PR #, commit hash
1. Update the commitHash and review app config when the PR is updated


### Config Requirements
1. Sort out the k8s permissions required and annotate the controller
1. I believe the AWS and Harbor permissions are already in the builder namespace and the same build jobs should work


### List of resources
- Build jobs
- TLS secret
- env secret
- kubedb init secret
- kubedb (postgres)
- deployment
- service
- ingress
