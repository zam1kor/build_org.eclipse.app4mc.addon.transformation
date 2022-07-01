FROM ubuntu:latest as build

VOLUME [ "/data" ]

RUN mkdir -p /opt/sources
RUN mkdir -p /opt/binaries

# install requirements
RUN apt-get update \
  && apt-get install -y git wget java-common maven

RUN cd /opt \
  && wget https://corretto.aws/downloads/latest/amazon-corretto-11-x64-linux-jdk.deb \
  && wget http://archive.ubuntu.com/ubuntu/pool/universe/m/maven/maven_3.6.3-5_all.deb \
  && chmod +X maven_3.6.3-5_all.deb \
  && chmod +X amazon-corretto-11-x64-linux-jdk.deb \
  && dpkg -i amazon-corretto-11-x64-linux-jdk.deb \
  && dpkg -i maven_3.6.3-5_all.deb


# checkout sources 

RUN cd /opt/sources \
  && git clone https://git.eclipse.org/r/app4mc/org.eclipse.app4mc.addon.transformation.git \
  && cd org.eclipse.app4mc.addon.transformation \
  && git checkout develop


# compiling sources

RUN cd /opt/sources/org.eclipse.app4mc.addon.transformation/load_generator \
  && mvn clean verify

# copying the jars 

WORKDIR /opt/sources/org.eclipse.app4mc.addon.transformation/load_generator

RUN cp ./releng/org.eclipse.app4mc.slg.ros2.product/target/ros2_slg.jar /opt/binaries

RUN cp ./releng/org.eclipse.app4mc.slg.linux.product/target/linux_slg.jar /opt/binaries



FROM ubuntu:latest as result

RUN mkdir -p /opt/sources
RUN mkdir -p /opt/binaries

# install requirements
RUN apt-get update \
  && apt-get install -y wget java-common maven

RUN cd /opt \
  && wget https://corretto.aws/downloads/latest/amazon-corretto-11-x64-linux-jdk.deb \
  && wget http://archive.ubuntu.com/ubuntu/pool/universe/m/maven/maven_3.6.3-5_all.deb \
  && chmod +X maven_3.6.3-5_all.deb \
  && chmod +X amazon-corretto-11-x64-linux-jdk.deb \
  && dpkg -i amazon-corretto-11-x64-linux-jdk.deb \
  && dpkg -i maven_3.6.3-5_all.deb


# install files from root
COPY --from=0 /opt/binaries/ /opt/binaries

WORKDIR /opt/binaries

ENV SLG_TYPE="NOT-USED"

CMD if [ "$SLG_TYPE" = "ROS2" ] ; \
     then \
          java -jar ros2_slg.jar \
    elif [ "$SLG_TYPE" = "LINUX" ] ;  \
    then \
          java -jar linux_slg.jar \
    fi