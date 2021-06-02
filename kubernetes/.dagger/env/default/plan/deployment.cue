package main

// Deployment template containing all the common boilerplate shared by
// deployments of this application.
#Deployment: {
	// name of the deployment. This will be used to automatically label resouces
	// and generate selectors.
	name: string

	// container image
	image: string

	// 80 is the default port
	port: *80 | int

	// Deployment manifest. Uses the name, image and port above to generate the
	// resource manifest.
	manifest: {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			"name": name
			labels: app: name
		}
		spec: {
			// 1 is the default, but we allow any number
			replicas: *1 | int
			selector: matchLabels: app: name
			template: {
				metadata: labels: app: name
				spec: containers: [{
					"name":  name
					"image": image
					ports: [{
						containerPort: port
					}]
				}]
			}
		}
	}
}
