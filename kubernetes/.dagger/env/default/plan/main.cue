package main

import (
	"encoding/yaml"

	"dagger.io/dagger"
	"dagger.io/kubernetes"
)

// input: source code repository
// set with `dagger input dir repository ./app`
repository: dagger.#Artifact @dagger(input)

// input: ~/.kube/config file used for deployment
// set with `dagger input text kubeconfig -f ~/.kube/config`
kubeconfig: string @dagger(input)

// deploy uses the `dagger.io/kubernetes` package to deploy manifests to a
// Kubernetes cluster.
deploy: kubernetes.#Apply & {
	// reference the `kubeconfig` input above
	"kubeconfig": kubeconfig

	// Marshal Cue definitions back to YAML for kubernetes.
	manifest: yaml.MarshalStream([
			// nginx deployment
			// defined in nginx.cue
			nginx.manifest,
			// app deployment
			// defined in app.cue
			app.manifest,
	])
}
