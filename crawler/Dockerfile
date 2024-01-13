FROM rust:buster as builder
ENV USER root
WORKDIR /crawler
COPY ./lemmy-federation-graph .
RUN cargo build --release

FROM debian:buster
ENV verbose 2
ENV neo4j_user neo4j
ENV neo4j_password neo4j
ENV neo4j_db neo4j
ENV neo4j_uri 127.0.0.1:7687
ENV store_jobs 1
ENV start_instances lemmy.ml
ENV max_distance 1
WORKDIR /app
COPY --from=builder /crawler/target/release/lemmy-stats-crawler .
CMD /app/lemmy-stats-crawler -v $verbose --neo4j-uri $neo4j_uri --neo4j-user $neo4j_user --neo4j-password $neo4j_password --neo4j-db $neo4j_db --store-jobs-count $store_jobs --start-instances $start_instances --max-crawl-distance $max_distance
