package com.lakehouse.ingestion;

import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.table.data.GenericRowData;
import org.apache.flink.table.data.RowData;
import org.apache.flink.table.data.StringData;
import org.apache.flink.table.data.TimestampData;
import org.apache.iceberg.Schema;
import org.apache.iceberg.PartitionSpec;
import org.apache.iceberg.catalog.TableIdentifier;
import org.apache.iceberg.flink.TableLoader;
import org.apache.iceberg.flink.sink.FlinkSink;
import org.apache.iceberg.flink.CatalogLoader;
import org.apache.iceberg.rest.RESTCatalog;
import org.apache.iceberg.types.Types;
import org.apache.hadoop.conf.Configuration;
import java.util.HashMap;
import java.util.Map;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.Serializable;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

/**
 * Skeleton for a Flink ClickStream Job.
 */
public class ClickStreamJob {

	public static class ClickEvent implements Serializable {
		public String event_id;
		public String user_id;
		public String game_id;
		public long timestamp;
	}

	public static void main(String[] args) throws Exception {
		// Setup Flink Stream Execution Environment
		final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

		// Enable checkpointing (every 10s) - required by Iceberg to commit data files
		env.enableCheckpointing(10000);

		// Configure Kafka Source
		KafkaSource<String> source = KafkaSource.<String>builder()
			.setBootstrapServers("local-kafka:29092")
			.setTopics("clickstream-events")
			.setGroupId("flink-clickstream-group")
			.setStartingOffsets(OffsetsInitializer.earliest())
			.setValueOnlyDeserializer(new SimpleStringSchema())
			.build();

		// Create Stream from Source
		DataStream<String> rawStream = env.fromSource(source, WatermarkStrategy.noWatermarks(), "Kafka Clickstream Source");

		// Deserialize JSON payload into ClickEvent POJOs
		ObjectMapper mapper = new ObjectMapper();
		DataStream<ClickEvent> eventStream = rawStream.map(new MapFunction<String, ClickEvent>() {
			@Override
			public ClickEvent map(String value) throws Exception {
				return mapper.readValue(value, ClickEvent.class);
			}
		});

		// Define Watermark strategy on ClickEvent, converting event timestamp (epoch seconds) to milliseconds
		WatermarkStrategy<ClickEvent> watermarkStrategy = WatermarkStrategy
			.<ClickEvent>forBoundedOutOfOrderness(Duration.ofMinutes(2))
			.withTimestampAssigner((event, timestamp) -> event.timestamp * 1000);

		DataStream<ClickEvent> watermarkedStream = eventStream.assignTimestampsAndWatermarks(watermarkStrategy);

		// Hadoop & S3 Configurations for MinIO S3A file system
		Configuration hadoopConf = new Configuration();
		hadoopConf.set("fs.s3a.endpoint", "http://local-minio:9000");
		hadoopConf.set("fs.s3a.access.key", "admin");
		hadoopConf.set("fs.s3a.secret.key", "supersecret");
		hadoopConf.set("fs.s3a.path.style.access", "true");
		hadoopConf.set("fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem");

		// Initialize RESTCatalog and verify/create Iceberg table schema programmatically
		Map<String, String> catalogProps = new HashMap<>();
		catalogProps.put("type", "rest");
		catalogProps.put("uri", "http://local-iceberg-rest:8181");
		catalogProps.put("warehouse", "s3a://lakehouse/");
		catalogProps.put("io-impl", "org.apache.iceberg.hadoop.HadoopFileIO");
		catalogProps.put("s3.endpoint", "http://local-minio:9000");
		catalogProps.put("s3.path-style-access", "true");
		catalogProps.put("aws.access-key-id", "admin");
		catalogProps.put("aws.secret-access-key", "supersecret");

		RESTCatalog catalog = new RESTCatalog();
		catalog.setConf(hadoopConf);
		catalog.initialize("rest_catalog", catalogProps);

		TableIdentifier tableId = TableIdentifier.of("default", "clickstream_events");

		Schema schema = new Schema(
			Types.NestedField.required(1, "event_id", Types.StringType.get()),
			Types.NestedField.required(2, "user_id", Types.StringType.get()),
			Types.NestedField.required(3, "game_id", Types.StringType.get()),
			Types.NestedField.required(4, "event_time", Types.TimestampType.withoutZone()),
			Types.NestedField.required(5, "event_date", Types.StringType.get())
		);

		PartitionSpec spec = PartitionSpec.builderFor(schema)
			.identity("event_date")
			.build();

		if (!catalog.tableExists(tableId)) {
			catalog.createTable(tableId, schema, spec);
		}

		// Convert POJO stream to RowData stream
		DataStream<RowData> rowStream = watermarkedStream.map(new MapFunction<ClickEvent, RowData>() {
			@Override
			public RowData map(ClickEvent event) throws Exception {
				DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd").withZone(ZoneId.of("UTC"));
				GenericRowData row = new GenericRowData(5);
				String dateStr = formatter.format(Instant.ofEpochSecond(event.timestamp));

				row.setField(0, StringData.fromString(event.event_id));
				row.setField(1, StringData.fromString(event.user_id));
				row.setField(2, StringData.fromString(event.game_id));
				row.setField(3, TimestampData.fromEpochMillis(event.timestamp * 1000));
				row.setField(4, StringData.fromString(dateStr));
				return row;
			}
		});

		// Build and append stream to Flink Iceberg Sink via REST Catalog Loader
		CatalogLoader catalogLoader = CatalogLoader.custom(
			"rest_catalog",
			catalogProps,
			hadoopConf,
			"org.apache.iceberg.rest.RESTCatalog"
		);
		TableLoader tableLoader = TableLoader.fromCatalog(catalogLoader, tableId);
		FlinkSink.forRowData(rowStream)
			.tableLoader(tableLoader)
			.append();

		env.execute("Clickstream Ingestion & Deduplication Pipeline");
	}
}
