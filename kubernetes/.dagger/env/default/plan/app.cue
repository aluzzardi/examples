package main

import (
	"dagger.io/docker"
)

// docker build and docker push the `repository` directory
image: docker.#Push & {
	source: docker.#Build & {
		source: repository
	}

	ref: "localhost:5000/app"
}

// use the `#Deployment` template to generate the kubernetes manifest
app: #Deployment & {
	name: "test"

	// use the reference of the image we just built
	// this creates a dependency: `app` will only be deployed after the image is
	// built and pushed.
	"image": image.ref
}
