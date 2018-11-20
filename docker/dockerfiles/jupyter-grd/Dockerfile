FROM gradiant/jupyter:5.7.0-spark2.3.0

LABEL maintainer="cgiraldo@gradiant.org"
LABEL organization="gradiant.org"

COPY original-spark-examples_2.11-2.3.2.jar /opt/spark/jars
COPY platformlibs-0.1.5-py3.6.egg /tmp/
RUN mkdir /etc/platformlibs && /usr/bin/python3 -m easy_install /tmp/platformlibs-0.1.5-py3.6.egg

COPY notebooks/* notebooks/
