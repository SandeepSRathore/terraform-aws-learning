#!/usr/bin/env bash
# Fetch the generated password from Secrets Manager and run SQL against the DB.
set -euo pipefail
cd "$(dirname "$0")"

HOST=$(terraform output -raw endpoint)
PORT=$(terraform output -raw port)
DB=$(terraform output -raw db_name)
SECRET=$(terraform output -raw master_secret_arn)

echo "--- instance"
aws rds describe-db-instances --db-instance-identifier demo-postgres \
  --query 'DBInstances[0].[DBInstanceStatus, Engine, EngineVersion, DBInstanceClass, Endpoint.Address, Endpoint.Port]' --output text

echo "--- the master password lives in Secrets Manager (RDS created it)"
CREDS=$(aws secretsmanager get-secret-value --secret-id "$SECRET" --query SecretString --output text)
USER=$(echo "$CREDS" | python3 -c 'import json,sys; print(json.load(sys.stdin)["username"])')
PASS=$(echo "$CREDS" | python3 -c 'import json,sys; print(json.load(sys.stdin)["password"])')
echo "username: $USER | password: ${PASS:0:3}****"

# psql from the postgres image. On LocalStack the DB listens on your Mac, which
# containers reach as host.docker.internal. On real AWS run psql from inside the VPC.
CONNECT_HOST=$HOST
[ -n "${AWS_ENDPOINT_URL:-}" ] && CONNECT_HOST=host.docker.internal
psql() { docker run --rm -i -e PGPASSWORD="$PASS" postgres:17-alpine psql -h "$CONNECT_HOST" -p "$PORT" -U "$USER" -d "$DB" -v ON_ERROR_STOP=1 -qAt "$@"; }

echo "--- SQL"
psql <<'SQL'
CREATE TABLE products (id serial PRIMARY KEY, name text NOT NULL, price numeric(8,2));
INSERT INTO products (name, price) VALUES ('keyboard', 49.90), ('mouse', 19.50);
SELECT 'server: ' || split_part(version(), ' on ', 1);
SELECT id || ' | ' || name || ' | ' || price FROM products ORDER BY id;
SQL

echo "--- take a manual snapshot (backups you keep until you delete them)"
aws rds create-db-snapshot --db-instance-identifier demo-postgres --db-snapshot-identifier demo-manual-1 \
  --query 'DBSnapshot.[DBSnapshotIdentifier, Status]' --output text
aws rds delete-db-snapshot --db-snapshot-identifier demo-manual-1 --query 'DBSnapshot.DBSnapshotIdentifier' --output text | sed 's/^/deleted snapshot: /'
