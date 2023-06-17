#!/bin/bash

if [[ $# -lt 2 ]] ; then
  echo "usage: $0 <neo4j-admin-user> <neo4j-admin-password>"
  exit 0
fi

db_name="${db_name:=fediverse}"
crawler_user="${crawler_user:=crawler}"
crawler_role="${crawler_role:=crawler}"
crawler_password="${crawler_password:=crawlerpassword}"
public_user="${public_user:=public}"
public_role="${public_role:=fediverse_reader}"
public_password="${public_password:=password}"

NEO4J_CONTAINER=$(docker-compose ps -q neo4j)
if [ -z $NEO4J_CONTAINER ] ; then
  echo "no existing neo4j container"
  exit 0
fi

if [ -n "$new_admin_password" ] ; then
  tee /proc/self/fd/2 <<EOF | docker exec -i $NEO4J_CONTAINER cypher-shell -u $1 -p $2 -d system
ALTER CURRENT USER SET PASSWORD FROM '$2' TO '$new_admin_password';
EOF
else
  new_admin_password=$2
fi

tee /proc/self/fd/2 <<EOF | docker exec -i $NEO4J_CONTAINER cypher-shell -u $1 -p $new_admin_password
CREATE DATABASE $db_name IF NOT EXISTS WAIT 10 SECONDS;
:use $db_name
CREATE CONSTRAINT instance_domain IF NOT EXISTS FOR (ins:Instance) REQUIRE ins.domain IS UNIQUE;
CREATE USER $crawler_user IF NOT EXISTS
  SET PLAINTEXT PASSWORD '$crawler_password'
  SET PASSWORD CHANGE NOT REQUIRED
  SET STATUS ACTIVE
  SET HOME DATABASE $db_name;
CREATE ROLE $crawler_role IF NOT EXISTS;
GRANT WRITE ON GRAPH $db_name TO $crawler_role;
GRANT MATCH {*} ON GRAPH $db_name TO $crawler_role;
GRANT ROLE $crawler_role TO $crawler_user;
GRANT CREATE NEW NODE LABEL ON DATABASE $db_name TO $crawler_role;
GRANT CREATE NEW PROPERTY NAME ON DATABASE $db_name TO $crawler_role;
GRANT CREATE NEW RELATIONSHIP TYPE ON DATABASE $db_name TO $crawler_role;

CREATE ROLE $public_role IF NOT EXISTS;
GRANT MATCH {*} ON GRAPH $db_name RELATIONSHIPS ALLOWS,BLOCKS,LINKED TO $public_role;
GRANT MATCH {*} ON GRAPH $db_name NODES Instance TO $public_role;
CREATE USER $public_user IF NOT EXISTS
  SET PLAINTEXT PASSWORD '$public_password'
  SET PASSWORD CHANGE NOT REQUIRED
  SET STATUS ACTIVE
  SET HOME DATABASE $db_name;
GRANT ROLE $public_role TO $public_user;

GRANT SHOW INDEX ON DATABASE $db_name TO $public_role;
GRANT SHOW CONSTRAINT ON DATABASE $db_name TO $public_role;
GRANT MATCH {*} ON GRAPH $db_name NODES _Bloom_Perspective_,_Bloom_Scene_ TO $public_role;
GRANT CREATE ON GRAPH $db_name NODES _Bloom_Perspective_,_Bloom_Scene_ TO $public_role;
GRANT SET PROPERTY {*} ON GRAPH $db_name NODES _Bloom_Perspective_,_Bloom_Scene_ TO $public_role;
EOF
# GRANT MERGE {*} ON GRAPH $db_name NODES _Bloom_Perspective_,_Bloom_Scene_ TO $public_role;