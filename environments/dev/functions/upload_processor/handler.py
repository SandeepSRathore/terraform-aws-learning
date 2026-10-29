"""Runs every time a file lands in uploads/ of the assets bucket.

Reads the file, counts lines/words/characters, and writes a small JSON
report to processed/<same name>.json. Anything print()ed goes to the
function's CloudWatch log group.
"""

import json
import os
import urllib.parse

import boto3  # the AWS SDK for Python; preinstalled in Lambda's Python runtime

# Created once per container, then reused by later runs ("warm starts").
s3 = boto3.client("s3")

INPUT_PREFIX = os.environ["INPUT_PREFIX"]
OUTPUT_PREFIX = os.environ["OUTPUT_PREFIX"]


def handler(event, context):
    # One event can carry several uploads, so loop over the records.
    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        # Keys arrive URL-encoded: "my file.txt" becomes "my+file.txt".
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        text = s3.get_object(Bucket=bucket, Key=key)["Body"].read().decode("utf-8", errors="replace")
        report = {
            "source": f"s3://{bucket}/{key}",
            "lines": len(text.splitlines()),
            "words": len(text.split()),
            "characters": len(text),
        }

        # Writing back into uploads/ would trigger this function again,
        # forever. Reports go to a different prefix (and IAM forbids it anyway).
        out_key = OUTPUT_PREFIX + key.removeprefix(INPUT_PREFIX) + ".json"
        s3.put_object(
            Bucket=bucket,
            Key=out_key,
            Body=json.dumps(report, indent=2),
            ContentType="application/json",
        )

        print(json.dumps({"processed": key, "report": out_key, **report}))

    return {"processed": len(event["Records"])}
