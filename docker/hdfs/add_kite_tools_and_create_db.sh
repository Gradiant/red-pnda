#!/bin/bash
export HADOOP_HOME=$HADOOP_PREFIX
export HADOOP_MAPRED_HOME=$HADOOP_PREFIX
export HIVE_HOME=/opt/apache-hive-2.1.0-bin
apk add --no-cache curl sudo
mkdir -p $HIVE_HOME/lib
curl http://central.maven.org/maven2/org/apache/hive/hive-common/2.1.0/hive-common-2.1.0.jar -o $HIVE_HOME/lib/hive-common-2.1.0.jar
curl http://central.maven.org/maven2/org/kitesdk/kite-tools/1.1.0/kite-tools-1.1.0-binary.jar -o /usr/local/bin/kite-dataset
chmod +x /usr/local/bin/kite-dataset
sudo -u pnda -E kite-dataset -v create --schema /tmp/pnda.avsc dataset:hdfs://hdfs-namenode:8020/user/pnda/PNDA_datasets/datasets --partition-by /tmp/pnda_kite_partition.json
