import json
import pathlib

from pyflink.common import Types
from pyflink.datastream import (StreamExecutionEnvironment, RuntimeExecutionMode, MapFunction,
    RuntimeContext, FlatMapFunction)
from pyflink.datastream.state import MapStateDescriptor


class SerializerMapFunction(MapFunction):
    """
    Custom map function to format readings in a compact way
    """
    def map(self, value):
        record = '|'.join([k + '=' + str(v) for k, v in value.items()])
        return record


class LookupKeyedProcessFunction(FlatMapFunction):
    """
    Function to track keyed sensor readings and emit additional events when an anomaly is detected.
    """
    def __init__(self):
        # We can define our state here, but it won't be available until the `open` lifecycle function is called
        self.lut_state = None

    def open(self, runtime_context: RuntimeContext):
        state_desc = MapStateDescriptor('LUT', Types.STRING(), Types.FLOAT())
        # Here we can fully register this operator's state and pass in it's type definition
        # (remember under the hood this translates into a Java object so it needs to be strongly typed)
        self.lut_state = runtime_context.get_map_state(state_desc)

    def flat_map(self, value):
        # get a handle on state reference
        lut = self.lut_state.get_internal_state()
        # try to get the previously tracked value (and default to the current if one doesn't exist yet)
        prev = lut.get(value.get("kind")) or value.get("value")
        # calculate the diff
        diff = abs(prev - value.get("value"))
        if diff > 1:
            # big diff :)
            yield {'id': value.get("id"), 'value': value.get("value"), 'message': 'Sensor offset alert!', 'delta': diff}
        # update the current state with this event's value
        # notice how we are mapping by kind so we can track multiple sensor readings if we wanted to
        self.lut_state.put(value.get("kind"), value.get("value"))
        yield value


def run():
    # Load the data from test file (this could also be done with Flink file connector)
    data = json.loads(pathlib.Path(__file__).parent.joinpath('../generators/sensors.json').read_text())
    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_runtime_mode(RuntimeExecutionMode.STREAMING)
    env.set_parallelism(1)

    (env.from_collection(data)
     # group events by sensor `id`
     .key_by(lambda x: x.get("id"), Types.STRING())
     # check for anomalies
     .flat_map(LookupKeyedProcessFunction(), output_type=Types.MAP(Types.STRING(), Types.STRING()))
     # use our custom serializer
     .map(SerializerMapFunction(), output_type=Types.STRING())
     .print())

    env.execute("sensors")


if (__name__ == '__main__'):
    run()
