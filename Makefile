

cpanfile.snapshot: cpanfile
	docker build --platform linux/amd64 --target snapshot -t riji-snapshot .
	docker run --rm --platform linux/amd64 -v $(PWD):/app -w /app riji-snapshot \
		sh -c 'carmel install && carmel update'
