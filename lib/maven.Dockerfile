FROM public.ecr.aws/docker/library/maven:3.9.5-amazoncorretto-11-debian AS builder

WORKDIR package

COPY *.jar /package
COPY pom.xml /package
RUN mvn -f /package/pom.xml clean package

FROM scratch as output
COPY --from=builder /package/target/pyflink-services-1.0.jar ./