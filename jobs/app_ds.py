from pyflink.common import Types
from pyflink.datastream import StreamExecutionEnvironment, RuntimeExecutionMode, MapFunction, KeyedProcessFunction, \
    RuntimeContext
from pyflink.datastream.state import MapStateDescriptor


class SerializerMapFunction(MapFunction):

    def map(self, value):
        print("serialize", value)
        record = '|'.join([k + '=' + v for k, v in value.items()])
        return record


class LookupKeyedProcessFunction(KeyedProcessFunction):

    def __init__(self):
        self.lut_state = None

    def open(self, runtime_context: RuntimeContext):
        state_desc = MapStateDescriptor('LUT', Types.STRING(), Types.STRING())
        self.lut_state = runtime_context.get_map_state(state_desc)
        self.lut_state.put("141", "red alert")

    def process_element(self, value, runtime_context: RuntimeContext):

        lut = self.lut_state.get_internal_state()

        if value.get("35") == "X":
            self.lut_state.put_all(value.items())
        if value.get("35") == "P":
            lookup = lut.get("141")

        print(value)
        yield value


def run():
    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_runtime_mode(RuntimeExecutionMode.STREAMING)
    env.set_parallelism(1)

    """
    map(DeserializerMapFunction(), output_type=Types.MAP(Types.STRING(),Types.STRING())) \
        .filter(TargetCompIdFilterFunction()) \
    """

    ds = env.from_collection([{"49": "1049"}, {"35": "X"}])
    ds.key_by(lambda x: x.get("49"), Types.STRING()) \
        .process(LookupKeyedProcessFunction(), output_type=Types.MAP(Types.STRING(), Types.STRING())) \
        .map(SerializerMapFunction(), output_type=Types.STRING()) \
        .print()

    env.execute("testeroni")


if (__name__ == '__main__'):
    run()
