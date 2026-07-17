use rdkafka::config::ClientConfig;
use rdkafka::producer::{FutureProducer, FutureRecord};
use serde::Serialize;
use std::time::Duration;
use chrono::Utc;
use rand::Rng;

#[derive(Serialize)]
struct ClickEvent {
    event_id: String,
    user_id: String,
    game_id: String,
    timestamp: i64,
}

#[tokio::main]
async fn main() {
    // Establish connection
    // FutureProducer allows us to create an async producer to queue messages and continue
    // processing without blocking the thread to wait for Kafka broker to reply
    let producer: FutureProducer = ClientConfig::new()
        .set("bootstrap.servers", "127.0.0.1:9092")
        .set("queue.buffering.max.messages", "100000") // Buffer up to 100k messages in memory
        .set("compression.codec", "snappy") // use Snappy compression, fast algo for shrinking network packets
        .create()
        .expect("Producer creation error");

    println!("Starting Rust High-Throughput Kafka Producer");

    let mut rng = rand::thread_rng();

    loop {
        let event = ClickEvent {
            event_id: uuid::Uuid::new_v4().to_string(),
            user_id: format!("user_{}", rng.gen_range(1..10000)),
            game_id: format!("game_{}", rng.gen_range(1..100)),
            timestamp: Utc::now().timestamp(),
        };

        let payload = serde_json::to_string(&event).unwrap();

        println!("{}", payload);

        // Async publish to Kafka
        // Key Partitioning (using user_id as the key) guarantees all events for a specific user
        // land on the same partition, maintaining chronological order
        let _ = producer.send(
            FutureRecord::to("cliclstrea-events")
                .payload(&payload)
                .key(&event.user_id),
            Duration::from_secs(0),
        ).await;

        tokio::time::sleep(Duration::from_micros(200)).await; // Emits 5000 events/second
    }
}