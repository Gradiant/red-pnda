PNDA_USER=pnda
PNDA_GROUP=pnda

define enable_thrift
echo "----------------  ENABLING THRIFT API in HBASE MASTER  ----------------"
docker exec -d hbase-master hbase thrift start -p 9090
while ! docker exec -ti hbase-master nc -vz hbase-master:9090 ; do \
  echo "waiting for hbase thrift api to start"; \
  sleep 2; \
done
endef

deploy-hdfs:
	docker-compose up -d zookeeper hdfs-namenode hdfs-datanode
	while ! docker exec -ti hdfs-namenode nc -vz hdfs-namenode:8020 ; do \
		echo "waiting for hdfs-namenode to start"; \
		sleep 2; \
	done
deploy-hbase: deploy-hdfs
	docker-compose up -d hbase-master
	docker-compose up -d hbase-region
	$(call enable_thrift)


deploy-kafka:
	docker-compose up -d kafka kafka-manager
	echo "----------------  KAFKA-MANAGER CONFIGURATION  ----------------"
	while ! docker exec -ti kafka-manager nc -vz localhost:10900 ; do \
	  echo "waiting for kafka-mnanager server to start"; \
	  sleep 2; \
	done
	docker exec -ti kafka-manager wget \
	--post-data='name=PNDA&zkHosts=zookeeper%3A2181&kafkaVersion=1.0.0&jmxEnabled=true&jmxUser=&jmxPass=&activeOffsetCacheEnabled=true&securityProtocol=PLAINTEXT' \
	http://localhost:10900/clusters -q -O/dev/null

deploy-spark:
	docker-compose up -d spark-master spark-worker

deploy-grafana:
	docker-compose up -d grafana

deploy-jupyter:
	docker-compose up -d jupyter jupyter-ssh
	docker exec jupyter-ssh sh -c 'adduser -D pnda && echo "pnda:pnda" | chpasswd'

deploy-pnda:
	docker-compose up -d gobblin package-repository platform-testing jmxproxy console-frontend \
	console-backend console-backend-data-logger redis data-service deployment-manager
	docker exec deployment-manager sh -c 'adduser -D pnda && echo "pnda:pnda" | chpasswd'

init-hbase-opentsdb:
	echo "----------------  CREATING HBASE TABLES for OPENTSDB  ----------------"
	docker exec -i hbase-master /bin/bash < opentsdb/create_opentsdb_hbase_tables.sh

init-hdfs:
	echo "----------------  ADDING users to HDFS  ----------------"
	echo "adding hdfs as admin superuser"
	docker exec -ti hdfs-namenode adduser --system --gecos "" --ingroup=root --shell /bin/bash --disabled-password hdfs
	echo "adding pnda user"
	docker exec -ti hdfs-namenode addgroup $(PNDA_GROUP)
	docker exec -ti hdfs-namenode adduser --gecos "" --ingroup=$(PNDA_GROUP) --shell /bin/bash --disabled-password $(PNDA_USER)
	docker exec -ti hdfs-namenode hdfs dfs -mkdir -p /user/$(PNDA_USER)
	docker exec -ti hdfs-namenode hdfs dfs -chown $(PNDA_USER):$(PNDA_GROUP) /user/$(PNDA_USER)
	docker exec -ti hdfs-namenode hdfs dfs -chmod 770 /user/$(PNDA_USER)
	echo "----------------  ADDING KITE_TOOLS to HDFS NAMENODE AND INITIALIZE PNDA REPOs  ----------------"
	docker cp hdfs/kite-files/pnda.avsc hdfs-namenode:/tmp/pnda.avsc
	docker cp hdfs/kite-files/pnda_kite_partition.json hdfs-namenode:/tmp/pnda_kite_partition.json
	docker cp hdfs/add_kite_tools_and_create_db.sh hdfs-namenode:/tmp/add_kite_tools_and_create_db.sh
	docker exec -ti hdfs-namenode /bin/bash -c /tmp/add_kite_tools_and_create_db.sh

create-dm-keys:
	echo "----------------  ADDING ssh keys to dm_keys volume   ----------------"
	mkdir -p dm_keys
	echo "Generating SSH Key for Deployment Manager connections"
			ssh-keygen -b 2048 -t rsa -f dm_keys/dm -q -N ""
	cp dm_keys/dm dm_keys/dm.pem
	docker cp dm_keys/ deployment-manager:/opt/pnda/
	docker exec -ti deployment-manager chown -R root:root /opt/pnda/dm_keys/
	docker exec -ti deployment-manager chmod 644 /opt/pnda/dm_keys/dm.pub
	docker exec -ti deployment-manager chmod 600 /opt/pnda/dm_keys/dm.pem
	docker exec -ti deployment-manager chmod 600 /opt/pnda/dm_keys/dm

distribute-dm-keys:
	echo "----------------  ADDING Public key to jupyter-ssh  ----------------"
	docker exec jupyter-ssh mkdir -p /home/pnda/.ssh
	docker cp dm_keys/dm.pub jupyter-ssh:/home/pnda/.ssh/authorized_keys
	docker exec jupyter-ssh chmod 644 /home/pnda/.ssh/authorized_keys
	docker exec jupyter-ssh chown -R pnda:pnda /home/pnda/.ssh
	docker exec jupyter-ssh mkdir -p /root/.ssh
	docker cp dm_keys/dm.pub jupyter-ssh:/root/.ssh/authorized_keys
	docker exec jupyter-ssh chmod 644 /root/.ssh/authorized_keys
	docker exec jupyter-ssh chown -R root:root /root/.ssh
	echo "----------------  ADDING Public key to deployment-manager-ssh  ----------------"
	#docker exec deployment-manager-ssh mkdir -p /root/.ssh
	#docker cp dm_keys/dm.pub deployment-manager-ssh:/root/.ssh/authorized_keys
	#docker exec deployment-manager-ssh chmod 644 /root/.ssh/authorized_keys
	#docker exec deployment-manager-ssh chown -R root:root /root/.ssh

deploy: deploy-hdfs deploy-hbase init-hdfs init-hbase-opentsdb deploy-kafka deploy-spark deploy-jupyter deploy-grafana deploy-pnda create-dm-keys distribute-dm-keys
	docker-compose up -d opentsdb
	./docker_local_resolution.sh enable

start:
	docker-compose up -d
	$(call enable_thrift)
	./docker_local_resolution.sh -y enable
stop:
	docker-compose down
	./docker_local_resolution.sh -y disable

clean:
	docker-compose down -v
	./docker_local_resolution.sh -y disable
	rm -rf dm_keys

ui:
	xdg-open http://console-frontend.pnda

