# Name of the image
name := mage/mage

# Default set of version for `make all`
versions ?= $(shell curl -L -s \
                    'https://registry.hub.docker.com/v2/repositories/library/node/tags?page_size=1024' \
                    | jq -r '.results[]["name"]' | grep -v onbuild )

.PHONY: build-version build release-version git-push push-all release

build-version:
	$(if $(findstring alpine,$(version)), \
	    docker build -t $(name):$(version) --build-arg=node_version=$(version) -f alpine/Dockerfile ., \
	    docker build -t $(name):$(version) --build-arg=node_version=$(version) -f debian/Dockerfile .)
	docker tag $(name):$(version) $(name):$(version)

build:
	for version in $(versions); do \
		echo ">> Building version $${version}"; \
		$(MAKE) build-version version=$${version} "versions=$(versions)" || exit $${?}; \
	done

release-version:
	docker push $(name):$(version)

push-all:
	for version in $(versions); do \
		echo ">> Pushing version $${version}"; \
		$(MAKE) release-version version=$${version} "versions=$(versions)" || exit $${?}; \
	done

git-push:
	git push git@github.com:mage/mage-docker.git master

release: git-push
	for version in $(versions); do \
		echo ">> Release version $${version}"; \
		$(MAKE) release-version version=$${version} "versions=$(versions)" || exit $${?}; \
	done
	$(MAKE) release-version version=latest
