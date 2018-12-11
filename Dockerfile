# Create an image to build Hadoop nativelibs
#
# docker build -t sequenceiq/hadoop-nativelibs .

FROM centos:7
MAINTAINER dvoros

USER root

RUN yum clean all

# install dev tools
RUN yum install -y curl which tar sudo openssh-server openssh-clients rsync bunzip2 && yum clean all

# cmake3 is coming from EPEL
RUN curl http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm > /tmp/epel.rpm
RUN rpm -i /tmp/epel.rpm && rm /tmp/epel.rpm
RUN yum install -y --enablerepo=epel cmake3
RUN ln -s /usr/bin/cmake3 /usr/bin/cmake

# install hadoop nativelins tools
RUN yum install -y gcc gcc-c++ autoconf automake libtool zlib-devel

# passwordless ssh
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

# java
RUN curl -LO 'http://download.oracle.com/otn-pub/java/jdk/8u171-b11/512cd62ec5174c3487ac17c61aaa89e8/jdk-8u171-linux-x64.rpm' -H 'Cookie: oraclelicense=accept-securebackup-cookie'
RUN rpm -i jdk-8u171-linux-x64.rpm
RUN rm jdk-8u171-linux-x64.rpm
ENV JAVA_HOME /usr/java/default
ENV PATH $PATH:$JAVA_HOME/bin

# devel tools
RUN yum groupinstall "Development Tools" -y
RUN yum install -y zlib-devel openssl-devel

# maven
ENV M2_VER=3.5.3
RUN curl http://www.eu.apache.org/dist/maven/maven-3/${M2_VER}/binaries/apache-maven-${M2_VER}-bin.tar.gz|tar xz  -C /usr/share
ENV M2_HOME /usr/share/apache-maven-${M2_VER}
ENV PATH $PATH:$M2_HOME/bin

# protoc -ohhh
RUN curl -L -k1 https://github.com/google/protobuf/releases/download/v2.5.0/protobuf-2.5.0.tar.bz2 | bunzip2 | tar -x -C /tmp
RUN cd /tmp/protobuf-2.5.0 && ./configure
RUN cd /tmp/protobuf-2.5.0 && make && make install
ENV LD_LIBRARY_PATH /usr/local/lib
ENV export LD_RUN_PATH /usr/local/lib

# hadoop
RUN curl -sk https://www.eu.apache.org/dist/hadoop/common/hadoop-3.1.1/hadoop-3.1.1-src.tar.gz | tar -xz -C /tmp/

# build native libs
RUN cd /tmp/hadoop-3.1.1-src && mvn package -Pdist,native -DskipTests -Dtar

# tar to stdout
RUN rm -r /tmp/hadoop-3.1.1-src/hadoop-dist/target/hadoop-3.1.1/lib/native/examples
CMD tar -czv -C /tmp/hadoop-3.1.1-src/hadoop-dist/target/hadoop-3.1.1/lib/native/ .

# Create native libs tar with:
# docker run --rm dvoros/docker-hadoop-build:3.1.1 > hadoop-native-64-3.1.1.tgz
