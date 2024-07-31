
FROM public.ecr.aws/docker/library/python:3.8 as aws_maf_builder
ARG APPLICATION_FILE
ARG DIST_ARTIFACT_NAME

RUN set -ex; \
  apt-get update && \
  apt-get install zip

WORKDIR /package

COPY ../jobs/${APPLICATION_FILE} /package/
COPY ../lib/bin/*.jar /package/lib/
COPY ../framework /package/modules/framework
COPY ../requirements.txt /package/


RUN pip install -r requirements.txt -t ./modules
RUN zip -r "${DIST_ARTIFACT_NAME}.zip" ${APPLICATION_FILE} ./lib ./modules ./framework

FROM scratch as output
ARG DIST_ARTIFACT_NAME

COPY --from=aws_maf_builder /package/${DIST_ARTIFACT_NAME}.zip /

