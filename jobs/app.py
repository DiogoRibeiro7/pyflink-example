from pyflink.table import EnvironmentSettings, TableEnvironment


def run():
    env_settings = EnvironmentSettings.in_streaming_mode()
    table_env = TableEnvironment.create(env_settings)

    table = table_env.from_elements([(1, 'Hi'), (2, 'Hello')], ['id', 'data'])
    table_env.create_temporary_view("simple_source", table)
    print(table.get_schema())

    table_env.execute_sql("""
        CREATE TABLE first_sink_table (
            id BIGINT, 
            data VARCHAR 
        ) WITH (
            'connector' = 'print'
        )
    """)

    table_env.execute_sql("""
        CREATE TABLE second_sink_table (
            id BIGINT, 
            data VARCHAR
        ) WITH (
            'connector' = 'print'
        )
    """)

    # create a statement set
    statement_set = table_env.create_statement_set()

    # emit the "table" object to the "first_sink_table"
    statement_set.add_insert("first_sink_table", table)

    # emit the "simple_source" to the "second_sink_table" via a insert sql query
    statement_set.add_insert_sql("INSERT INTO second_sink_table SELECT * FROM simple_source")

    # execute the statement set
    statement_set.execute().wait()


if (__name__ == '__main__'):
    run()
