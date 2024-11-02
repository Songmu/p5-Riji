

cpanfile.snapshot: cpanfile
	docker run --rm --platform linux/amd64 -v $(PWD):/app -w /app debian:stable-slim \
		sh -c '\
			apt-get update && \
			apt-get upgrade -y && \
			apt-get install -yq \
			  perl \
			  build-essential \
			  cpanminus && \
			apt-get clean && \
			cpanm -n Carmel && \
			carmel install'
