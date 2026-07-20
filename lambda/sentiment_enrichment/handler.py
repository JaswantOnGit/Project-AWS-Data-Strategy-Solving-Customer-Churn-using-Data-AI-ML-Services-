import base64
import json
import os

import boto3

comprehend = boto3.client("comprehend")

LANGUAGE_CODE = os.environ.get("LANGUAGE_CODE", "en")


def handler(event, context):
    """
    Triggered by a Kinesis Firehose data transformation.
    Each record's payload is a raw social-mention JSON blob:
      { "userid": "...", "text": "...", "timestamp": "..." }
    Enriches it with sentiment + key phrases via Amazon Comprehend
    and returns the transformed record for Firehose to deliver to S3.
    """
    output = []

    for record in event["records"]:
        payload = base64.b64decode(record["data"]).decode("utf-8")
        mention = json.loads(payload)

        text = mention.get("text", "")
        enriched = dict(mention)

        if text.strip():
            sentiment_resp = comprehend.detect_sentiment(
                Text=text, LanguageCode=LANGUAGE_CODE
            )
            phrases_resp = comprehend.detect_key_phrases(
                Text=text, LanguageCode=LANGUAGE_CODE
            )

            enriched["sentiment"] = sentiment_resp["Sentiment"]
            enriched["sentiment_score"] = sentiment_resp["SentimentScore"]
            enriched["key_phrases"] = [
                kp["Text"] for kp in phrases_resp["KeyPhrases"]
            ]
        else:
            enriched["sentiment"] = "UNKNOWN"
            enriched["key_phrases"] = []

        output.append(
            {
                "recordId": record["recordId"],
                "result": "Ok",
                "data": base64.b64encode(
                    (json.dumps(enriched) + "\n").encode("utf-8")
                ).decode("utf-8"),
            }
        )

    return {"records": output}
