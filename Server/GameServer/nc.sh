#!/bin/bash
port=$1
echo "port=$port"
nc 127.0.0.1 $port
