FROM flink:latest


# install jdk, python3, and pip3
RUN apt-get update -y && \
apt-get install -y openjdk-11-jdk-headless python3 python3-pip python3-dev && rm -rf /var/lib/apt/lists/*
RUN ln -s /usr/bin/python3 /usr/bin/python

# install PyFlink
RUN JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64 pip3 install apache-flink==1.19.1
#
### Iceberg Flink Library
#RUN curl -L https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-flink-runtime-1.16/1.3.1/iceberg-flink-runtime-1.16-1.3.1.jar -o /opt/flink/lib/iceberg-flink-runtime-1.16-1.3.1.jar
#
### Hive Flink Library
#RUN curl -L https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-hive-2.3.9_2.12/1.16.1/flink-sql-connector-hive-2.3.9_2.12-1.16.1.jar -o /opt/flink/lib/flink-sql-connector-hive-2.3.9_2.12-1.16.1.jar
#
### Hadoop Common Classes
#RUN curl -L https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/2.8.3/hadoop-common-2.8.3.jar -o /opt/flink/lib/hadoop-common-2.8.3.jar
#
### Hadoop AWS Classes
#RUN curl -L https://repo.maven.apache.org/maven2/org/apache/flink/flink-shaded-hadoop-2-uber/2.8.3-10.0/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar -o /opt/flink/lib/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar
#
### AWS Bundled Classes
#RUN curl -L https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/2.20.18/bundle-2.20.18.jar -o /opt/flink/lib/bundle-2.20.18.jar


COPY ./test/test_data/ /opt/test/test_data
COPY ./local/dist/ /opt/develop
COPY ./output/ /opt/output
COPY ./local/flink-conf.yaml /opt/flink/conf/flink-conf.yaml
RUN chmod a+rwx -R /opt/output