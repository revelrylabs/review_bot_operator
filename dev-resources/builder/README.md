### Fake Builder Image

This is the source for the dummy build job you can use for testing w/o having to set up all of the prerequisites for Kaniko and the AWS copy utility.

By using `grossvogel/sleep45:latest` as the build image in the dev configuration, we get a fake build job that sleeps for 90 seconds (45 in the unpack initContainer and 45 in the main build container) instead of building actual images. This means we also need to use a prebuilt stub app image in our deployments as well.
