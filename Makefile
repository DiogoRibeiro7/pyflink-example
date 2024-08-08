## Better defaults for make (thanks https://tech.davis-hansson.com/p/make/)
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
.SECONDEXPANSION:

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
	cd lib
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
	docker compose up --build

.PHONY: run
run:
	docker compose exec jobmanager ./bin/flink run -py /opt/develop/${app} -pyarch /opt/develop/py_deps.zip --jarfile /opt/develop/lib/pyflink-services-1.0.jar


.PHONY: test_put_kinesis
test_put_kinesis:
	export AWS_ACCESS_KEY_ID="test"
	export AWS_SECRET_ACCESS_KEY="test"
	export AWS_DEFAULT_REGION="us-east-1"
	$(eval DATA = $(shell echo $(testdata) | base64))
	aws kinesis put-record --stream-name input_stream --partition-key 123 --data $(DATA) --endpoint-url http://localhost:4566

.PHONY: test_get_kinesis
test_get_kinesis:
	$(eval SHARD_ITERATOR = $(shell aws kinesis get-shard-iterator --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --stream-name output_stream --query 'ShardIterator' --endpoint-url http://localhost:4566))
	$(info ${SHARD_ITERATOR})
	# read the records, use `jq` to grab the data of the first record, and base64 decode it
	aws kinesis get-records --shard-iterator $(SHARD_ITERATOR) --endpoint-url http://localhost:4566 | jq -r '.Records'


.PHONY: create_table_ddb
create_table_ddb:
	aws dynamodb create-table \
		--endpoint-url http://localhost:8000 \
		--table-name PyFlinkTestTable \
		--attribute-definitions AttributeName=id,AttributeType=S AttributeName=timestamp,AttributeType=S \
		--key-schema AttributeName=id,KeyType=HASH AttributeName=timestamp,KeyType=RANGE \
		--provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1

.PHONY: remove_table_ddb
remove_table_ddb:
	aws dynamodb delete-table \
		--endpoint-url http://localhost:8000 \
		--table-name PyFlinkTestTable

.PHONY: scan_table_ddb
scan_table_ddb:
	aws dynamodb scan --table-name PyFlinkTestTable --endpoint-url http://localhost:8000