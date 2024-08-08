import os
from os import path
from typing import Dict

from pyflink.common.serialization import SimpleStringSchema
from pyflink.datastream import (StreamExecutionEnvironment, RuntimeExecutionMode)
from pyflink.datastream.connectors.kinesis import (FlinkKinesisConsumer, KinesisStreamsSink, PartitionKeyGenerator)

LOCAL_DEBUG = os.getenv('LOCAL_DEBUG', False)


def get_source(stream_name: str, config: Dict = None) -> FlinkKinesisConsumer:
    props = config or {}
    consumer_config = {
        'aws.region': 'us-east-1',
        'aws.credentials.provider.basic.accesskeyid': 'localstack_ignored',
        'aws.credentials.provider.basic.secretkey': 'localstack_ignored',
        'flink.stream.initpos': 'LATEST',
        'aws.endpoint': 'http://localhost:4566',
        **props
    }
    return FlinkKinesisConsumer(stream_name, SimpleStringSchema(), consumer_config)


def get_sink(stream_name: str, config: Dict = None) -> KinesisStreamsSink:
    props = config or {}
    sink_properties = {
        'aws.region': 'us-east-1',
        'aws.credentials.provider.basic.accesskeyid': 'aws_access_key_id',
        'aws.credentials.provider.basic.secretkey': 'aws_secret_access_key',
        'aws.endpoint': 'http://localhost:4566',
        **props
    }

    return (KinesisStreamsSink.builder()
            .set_kinesis_client_properties(sink_properties)
            .set_serialization_schema(SimpleStringSchema())
            .set_partition_key_generator(PartitionKeyGenerator.fixed())
            .set_stream_name(stream_name)
            .build())


def run():
    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_runtime_mode(RuntimeExecutionMode.STREAMING)
    env.set_parallelism(1)

    # To enable local running/debugging, we manually add the project's shadow jar that has all the connectors built in
    if LOCAL_DEBUG:
        jar_location = str(path.join(path.dirname(path.abspath(__file__)), "../lib/bin/pyflink-services-1.0.jar"))
        env.add_jars(f"file:///{jar_location}")
        env.add_classpaths(f"file:///{jar_location}")

    # Kinesis source definition

    # Build a Datastream from the Kinesis source
    stream = env.add_source(get_source('input_stream'))

    # Kinesis sink definition
    sink = get_sink('PyFlinkTestTable')

    # sink the Datastream from the Kinesis source
    stream.sink_to(sink)

    env.execute("kinesis-2-dynamoDB")


if __name__ == '__main__':
    run()
