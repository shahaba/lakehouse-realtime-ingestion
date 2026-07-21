FROM flink:1.19.0-java17

# Create the plugin directory and activate the S3 filesystem handler
RUN mkdir -p /opt/flink/plugins/s3-fs-hadoop && \
    cp /opt/flink/opt/flink-s3-fs-hadoop-*.jar /opt/flink/plugins/s3-fs-hadoop/
