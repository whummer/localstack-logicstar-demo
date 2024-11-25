import pytest
import time
import boto3
import json
import requests
import localstack.sdk.aws
import localstack.sdk.chaos
from localstack.sdk.models import FaultRule
from localstack.sdk.chaos.managers import fault_configuration

LOCALSTACK_ENDPOINT = "http://localhost.localstack.cloud:4566"
QUEUE_NAME = "QuizSubmissionQueue"
SENDER_EMAIL = "admin@localstack.com"

class TestLocalStackClient:
    client = localstack.sdk.chaos.ChaosClient()

    @pytest.fixture(scope="module")
    def sqs_client(self):
        return boto3.client("sqs", endpoint_url=LOCALSTACK_ENDPOINT)

    def test_pipes_sqs_sns_integration(self, sqs_client):
        outage_rule = FaultRule(region="us-east-1", service="lambda")

        with fault_configuration(fault_rules=[outage_rule]):
            print("Lambda service outage initiated.")

            # Retrieve SQS queue URL
            response = sqs_client.get_queue_url(QueueName=QUEUE_NAME)
            queue_url = response["QueueUrl"]
            print(f"SQS Queue URL: {queue_url}")

            # Send a message to the SQS queue
            message_body = {"test": "message"}
            response = sqs_client.send_message(
                QueueUrl=queue_url,
                MessageBody=json.dumps(message_body),
            )
            assert response["ResponseMetadata"]["HTTPStatusCode"] == 200
            print(f"Message sent to SQS queue {QUEUE_NAME}: {message_body}")

            print("Waiting for system to process message during Lambda outage...")
            time.sleep(15)

        print("Outage resolved, checking SES for notifications...")

        ses_url = f"{LOCALSTACK_ENDPOINT}/_aws/ses"
        response = requests.get(ses_url)
        response.raise_for_status()
        messages_data = response.json()

        email_found = False
        expected_subject = "SNS-Subscriber-Endpoint"
        expected_body_text_part_contains = "QuizSubmissionQueue"
        SENDER_EMAIL = "admin@localstack.com"

        messages = messages_data.get("messages", [])

        for message in messages:
            if message["Source"] == SENDER_EMAIL:
                email_found = True
                assert message["Subject"] == expected_subject, f"Subject mismatch. Expected: {expected_subject}, Found: {message['Subject']}"
                assert "Body" in message, "Message body missing."
                
                body = message["Body"]
                assert "text_part" in body, "Text part missing in body."
                text_part = body["text_part"]
                assert expected_body_text_part_contains in text_part, f"Expected content not found in text part: {expected_body_text_part_contains}"

                print(f"Email found with subject '{expected_subject}' and matching body content.")
                break

        assert email_found, f"No email found sent from {SENDER_EMAIL} with subject '{expected_subject}'."

        print("Test completed successfully.")
