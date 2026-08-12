#!/bin/bash
# Quick Start Backend
cd /home/hduser/ev-charging-station-availability-analytics/backend
export HADOOP_HOME=/usr/local/hadoop
export HIVE_HOME=/usr/local/hive
export PATH=$HADOOP_HOME/bin:$HIVE_HOME/bin:$PATH
python3 main.py
