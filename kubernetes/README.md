# Kubernetes

This example illustrates how to use `dagger` to build, push and deploy Docker
images to Kubernetes.

## Preparation: Installing a local Kubernetes cluster

While dagger supports GKE and EKS, for the purpose of this example, we'll be
using [kind](https://kind.sigs.k8s.io/) to install a local Kubernetes cluster
in addition to a local container registry, no cloud account required.

1\. Install kind

On macOS:

```console
brew install kind
```

Otherwise, if you have [go](https://golang.org/) installed:

```console
go get sigs.k8s.io/kind@v0.11.0
```

2\. Start a local registry

```console
docker run -d -p 5000:5000 --name registry registry:2
```

3\. Create a cluster with the local registry enabled in containerd

```bash
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5000"]
    endpoint = ["http://registry:5000"]
EOF
```

4\. Make sure the cluster works

```console
kubectl cluster-info --context kind-kind
```

5\. Connect the registry to the cluster network

```console
docker network connect kind registry
```

## Deploying Locally

### Inputs

If we try to bring up the configuration, dagger will complain about missing inputs:

```console
$ dagger up
6:53PM ERR system | required input is missing    input=repository
6:53PM ERR system | required input is missing    input=kubeconfig
```

You can inspect the list of inputs (both required and optional) using `dagger input list`:

```console
$ dagger input list
Input             Type              Description
repository        dagger.#Artifact  source code repository of the application
kubeconfig        string            ~/.kube/config file used for deployment
deploy.namespace  string            Kubernetes Namespace to deploy to
```

Let's provide the two missing inputs:

```console
# we'll use the ~/.kube/config created by `kind`
dagger input text kubeconfig -f ~/.kube/config

# `./app` contains the source code of the application
dagger input dir repository ./app
```

### dagger up

Once the setup is done, you can build push and deploy the application by running
`dagger up`:

```console
$ dagger up
repository | computing
repository | completed    duration=0s
image | computing
image | completed    duration=1s
deploy | computing
deploy | #26 0.700 deployment.apps/nginx created
deploy | #26 0.709 deployment.apps/test created
deploy | completed    duration=900ms
```

Let's verify the deployment worked:

```console
$ kubectl get deployments
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   1/1     1            1           1m
test    1/1     1            1           1m
```

## Deploying to a Cloud

Once the deployment works in a local Kubernetes cluster, it's trivial to point
to a Cloud provider.

### GKE

 To deploy to GKE, we’re going to add a few lines to our plan. You can do this
 in a new file (for example gke.cue), or modify an existing cue file.

```cue
package main

import "dagger.io/gcp/gke"

gkeConfig: gke.#KubeConfig @dagger(input)
kubeconfig: gkeConfig.kubeconfig
```

This creates a new input called gkeConfig, and uses it to automatically generate
a value for the kubeConfig input.

```console
$ dagger input list
Input                        Type              Description
gkeConfig.config.region      string            GCP region
gkeConfig.config.project     string            GCP project
gkeConfig.config.serviceKey  dagger.#Secret    GCP service key
gkeConfig.clusterName        string            GKE cluster name

$ dagger input text gkeConfig.config.region <REGION>
$ dagger input text gkeConfig.config.project <PROJECT>
$ dagger input text gkeConfig.config.serviceKey -f <PATH TO THE SERVICEKEY.json>
$ dagger input text gkeConfig.clusterName <GKE CLUSTER NAME>

$ dagger up
...
```

### EKS

To deploy to Amazon EKS, we’re going to add a few lines to our plan. You can do
this in a new file (for example ecs.cue), or modify an existing cue file.

```cue
package main

import "dagger.io/aws/eks"

eksConfig: eks.#KubeConfig @dagger(input)
kubeconfig: eksConfig.kubeconfig
```

This creates a new input called eksConfig, and uses it to automatically generate
a value for the kubeConfig input.

```console
$ dagger input list
Input                       Type              Description
eksConfig.config.region     string            AWS region
eksConfig.config.accessKey  dagger.#Secret    AWS access key
eksConfig.config.secretKey  dagger.#Secret    AWS secret key
eksConfig.clusterName       string            EKS cluster name

$ dagger input text eksConfig.config.region <REGION>
$ dagger input text eksConfig.config.accessKey <ACCESS KEY>
$ dagger input text eksConfig.config.secretKey <SECRET KEY>
$ dagger input text eksConfig.clusterName <EKS CLUSTER NAME>

$ dagger up
...
```
