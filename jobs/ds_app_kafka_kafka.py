import os
from os import path

from pyflink.common import SimpleStringSchema, WatermarkStrategy
from pyflink.datastream import (StreamExecutionEnvironment, RuntimeExecutionMode)
from pyflink.datastream.connectors.base import DeliveryGuarantee
from pyflink.datastream.connectors.kafka import (KafkaSource,
                                                 KafkaOffsetsInitializer, KafkaSink, KafkaRecordSerializationSchema)

LOCAL_DEBUG = os.getenv('LOCAL_DEBUG', False)


def run():
    brokers = "localhost:9092"
    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_runtime_mode(RuntimeExecutionMode.STREAMING)
    env.set_parallelism(1)

    # To enable local running/debugging, we manually add the project's shadow jar that has all the connectors built in
    if LOCAL_DEBUG:
        jar_location = str(path.join(path.dirname(path.abspath(__file__)), "../lib/bin/pyflink-services-1.0.jar"))
        env.add_jars(f"file:///{jar_location}")
        env.add_classpaths(f"file:///{jar_location}")

    # Kafka source definition
    source = (KafkaSource.builder()
              .set_bootstrap_servers(brokers)
              .set_topics("input_topic")
              .set_group_id("stream_example")
              .set_starting_offsets(KafkaOffsetsInitializer.earliest())
              .set_value_only_deserializer(SimpleStringSchema())
              .build())
    # Build a Datastream from the Kafka source
    stream = env.from_source(source, WatermarkStrategy.no_watermarks(), "Kafka Source")

    # Kafka sink definition
    sink = (KafkaSink.builder()
            .set_bootstrap_servers(brokers)
            .set_record_serializer(
        KafkaRecordSerializationSchema.builder()
        .set_topic("output_topic")
        .set_value_serialization_schema(SimpleStringSchema())
        .build()
    )
            .set_delivery_guarantee(DeliveryGuarantee.AT_LEAST_ONCE)
            .build())

    # sink the Datastream from the Kafka source
    stream.sink_to(sink)

    env.execute("kafka-2-kafka")


if __name__ == '__main__':
    run()
