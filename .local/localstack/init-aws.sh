#!/bin/bash
awslocal kinesis create-stream --stream-name input_stream --shard-count  1
awslocal kinesis create-stream --stream-name output_stream --shard-count  1
