VENV:=. ./.venv/bin/activate

ifndef app
app := app.py
endif

.PHONY: fresh
fresh:
	rm -rf .venv
	virtualenv .venv
	@make deps
	@echo Activate the virtual environment by typing 'source ./.venv/bin/activate'

.PHONY: package_aws
package_aws: clean jar
	DOCKER_BUILDKIT=1 docker build --build-arg APPLICATION_FILE=${application} --build-arg DIST_ARTIFACT_NAME=pyflink-example -t pyflink/example -f ./aws/MAF.Dockerfile --output ./dist .

.PHONY: package_local
package_local: clean jar
	DOCKER_BUILDKIT=1 docker build --build-arg --build-arg -t pyflink/local -f ./local/Dockerfile --output ./local/dist .


.PHONY: jar
jar:
	DOCKER_BUILDKIT=1
	@docker build -t pyflink/jarbundler -f ./maven.Dockerfile --output ../lib/bin .

clean:
	rm -rf ./dist
	rm -rf ./local/dist


deps:
	$(VENV)
	pip install -r ./requirements.txt


build: package_aws

.PHONY: services
services:
	docker-compose up --build

.PHONY: run
run:
	docker-compose exec jobmanager ./bin/flink run -py /opt/develop/${app} -pyarch /opt/develop/py_deps.zip --jarfile /opt/develop/lib/pyflink-services-1.0.jar