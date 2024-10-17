#!/bin/bash

awslocal dynamodb create-table \
    --table-name Quizzes \
    --attribute-definitions AttributeName=QuizID,AttributeType=S \
    --key-schema AttributeName=QuizID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --output text

awslocal dynamodb create-table \
    --table-name UserSubmissions \
    --attribute-definitions \
        AttributeName=SubmissionID,AttributeType=S \
        AttributeName=QuizID,AttributeType=S \
        AttributeName=Score,AttributeType=N \
    --key-schema AttributeName=SubmissionID,KeyType=HASH \
    --global-secondary-indexes \
        '[
            {
                "IndexName": "QuizID-Score-index",
                "KeySchema": [
                    {"AttributeName": "QuizID", "KeyType": "HASH"},
                    {"AttributeName": "Score", "KeyType": "RANGE"}
                ],
                "Projection": {"ProjectionType": "ALL"},
                "ProvisionedThroughput": {"ReadCapacityUnits": 5, "WriteCapacityUnits": 5}
            }
        ]' \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --output text

awslocal sqs create-queue --queue-name QuizSubmissionQueue

zip -j get_quiz_function.zip lambdas/get_quiz/handler.py
zip -j create_quiz_function.zip lambdas/create_quiz/handler.py
zip -j submit_quiz_function.zip lambdas/submit_quiz/handler.py
zip -j scoring_function.zip lambdas/scoring/handler.py
zip -j get_submission_function.zip lambdas/get_submission/handler.py
zip -j get_leaderboard_function.zip lambdas/get_leaderboard/handler.py
zip -j list_quizzes_function.zip lambdas/list_quizzes/handler.py
zip -j retry_quizzes_writes_function.zip lambdas/retry_quizzes_writes/handler.py

# Deploy Lambdas

# GetQuizFunction
awslocal lambda create-function \
    --function-name GetQuizFunction \
    --runtime python3.8 \
    --handler handler.lambda_handler \
    --zip-file fileb://get_quiz_function.zip \
    --role arn:aws:iam::000000000000:role/DummyRole \
    --timeout 30 \
    --output text

# CreateQuizFunction
awslocal lambda create-function \
    --function-name CreateQuizFunction \
    --runtime python3.8 \
    --handler handler.lambda_handler \
    --zip-file fileb://create_quiz_function.zip \
    --role arn:aws:iam::000000000000:role/DummyRole \
    --timeout 30 \
    --output text

# SubmitQuizFunction
awslocal lambda create-function \
    --function-name SubmitQuizFunction \
    --runtime python3.8 \
    --handler handler.lambda_handler \
    --zip-file fileb://submit_quiz_function.zip \
    --role arn:aws:iam::000000000000:role/DummyRole \
    --timeout 30 \
    --output text

# ScoringFunction
awslocal lambda create-function \
    --function-name ScoringFunction \
    --runtime python3.8 \
    --handler handler.lambda_handler \
    --zip-file fileb://scoring_function.zip \
    --role arn:aws:iam::000000000000:role/DummyRole \
    --timeout 30 \
    --output text

# GetSubmissionFunction
awslocal lambda create-function \
    --function-name GetSubmissionFunction \
    --runtime python3.8 \
    --handler handler.lambda_handler \
    --zip-file fileb://get_submission_function.zip \
    --role arn:aws:iam::000000000000:role/DummyRole \
    --timeout 30 \
    --output text

# GetLeaderboardFunction
awslocal lambda create-function \
    --function-name GetLeaderboardFunction \
    --runtime python3.8 \
    --handler handler.lambda_handler \
    --zip-file fileb://get_leaderboard_function.zip \
    --role arn:aws:iam::000000000000:role/DummyRole \
    --timeout 30 \
    --output text

# ListQuizzes Function
awslocal lambda create-function \
    --function-name ListPublicQuizzesFunction \
    --runtime python3.8 \
    --handler handler.lambda_handler \
    --zip-file fileb://list_quizzes_function.zip \
    --role arn:aws:iam::000000000000:role/DummyRole \
    --timeout 30 \
    --output text

# Retry Quiz Writes
awslocal lambda create-function \
    --function-name RetryQuizzesWritesFunction \
    --runtime python3.8 \
    --handler handler.lambda_handler \
    --zip-file fileb://retry_quizzes_writes_function.zip \
    --role arn:aws:iam::000000000000:role/DummyRole \
    --timeout 30 \
    --output text

# SQS Trigger

QUEUE_URL=$(awslocal sqs get-queue-url --queue-name QuizSubmissionQueue --query 'QueueUrl' --output text)
QUEUE_ARN=$(awslocal sqs get-queue-attributes --queue-url $QUEUE_URL --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)

awslocal lambda create-event-source-mapping \
    --function-name ScoringFunction \
    --batch-size 10 \
    --event-source-arn $QUEUE_ARN

# Create REST API

API_ID=$(awslocal apigateway create-rest-api \
    --name 'QuizAPI' \
    --query 'id' --output text)

# Get Root Resource ID

PARENT_ID=$(awslocal apigateway get-resources \
    --rest-api-id $API_ID \
    --query 'items[0].id' --output text)

# GetQuiz endpoint

RESOURCE_ID=$(awslocal apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $PARENT_ID \
    --path-part getquiz \
    --query 'id' --output text)

awslocal apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --authorization-type "NONE"

awslocal apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:GetQuizFunction/invocations

# CreateQuiz endpoint

RESOURCE_ID=$(awslocal apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $PARENT_ID \
    --path-part createquiz \
    --query 'id' --output text)

awslocal apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --authorization-type "NONE"

awslocal apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:CreateQuizFunction/invocations

# SubmitQuiz endpoint

RESOURCE_ID=$(awslocal apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $PARENT_ID \
    --path-part submitquiz \
    --query 'id' --output text)

awslocal apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --authorization-type "NONE"

awslocal apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:SubmitQuizFunction/invocations

# Create GetSubmission endpoint
RESOURCE_ID=$(awslocal apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $PARENT_ID \
    --path-part getsubmission \
    --query 'id' --output text)

awslocal apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --authorization-type "NONE"

awslocal apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:GetSubmissionFunction/invocations

# Create GetLeaderboard endpoint
RESOURCE_ID=$(awslocal apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $PARENT_ID \
    --path-part getleaderboard \
    --query 'id' --output text)

awslocal apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --authorization-type "NONE"

awslocal apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:GetLeaderboardFunction/invocations

# ListQuizzes endpoint

RESOURCE_ID=$(awslocal apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $PARENT_ID \
    --path-part listquizzes \
    --query 'id' --output text)

awslocal apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --authorization-type "NONE"

awslocal apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:ListPublicQuizzesFunction/invocations

# Deploy

awslocal apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name test

API_ENDPOINT="http://localhost:4566/restapis/$API_ID/test/_user_request_"


# SQS DLQ —> EventBridge Pipes —> SNS
# To test this, add:
# raise Exception("Simulated failure in ScoringFunction for testing SNS DLQ.")
# in the `scoring_function.py` file and update the Lambda.
SNS_TOPIC_ARN=$(awslocal sns create-topic --name DLQAlarmTopic --output json | jq -r '.TopicArn')
DLQ_URL=$(awslocal sqs create-queue --queue-name QuizSubmissionDLQ --output json | jq -r '.QueueUrl')
DLQ_ARN=$(awslocal sqs get-queue-attributes --queue-url $DLQ_URL --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)

awslocal sqs set-queue-attributes \
    --queue-url $QUEUE_URL \
    --attributes '{
        "RedrivePolicy": "{\"deadLetterTargetArn\":\"'$DLQ_ARN'\",\"maxReceiveCount\":\"1\"}",
        "VisibilityTimeout": "10"
    }'

awslocal ses verify-email-identity --email your.email@example.com

awslocal sns subscribe \
    --topic-arn $SNS_TOPIC_ARN \
    --protocol email \
    --notification-endpoint your.email@example.com

awslocal pipes create-pipe \
  --name DLQToSNSPipe \
  --source $DLQ_ARN \
  --target $SNS_TOPIC_ARN \
  --role-arn arn:aws:iam::000000000000:role/DummyRole

awslocal stepfunctions create-state-machine \
    --name SendEmailStateMachine \
    --definition file://statemachine.json \
    --role-arn arn:aws:iam::000000000000:role/DummyRole

echo $API_ENDPOINT

pushd frontend
npm install
npm run build
awslocal s3 mb s3://webapp
awslocal s3 sync --delete ./build s3://webapp
awslocal s3 website s3://webapp --index-document index.html --error-document index.html
popd

awslocal cloudfront create-distribution --distribution-config file://distribution-config.json --output text
DISTRIBUTION=$(awslocal cloudfront create-distribution --distribution-config file://distribution-config.json)
DOMAIN_NAME=$(echo "$DISTRIBUTION" | jq -r '.Distribution.DomainName')
echo $DOMAIN_NAME

# Chaos Setup
awslocal sns create-topic --name QuizzesWriteFailures --output json

WRITE_FAILURES_QUEUE_URL=$(awslocal sqs create-queue --queue-name QuizzesWriteFailuresQueue --attributes VisibilityTimeout=60 --output json | jq -r '.QueueUrl')
WRITE_FAILURES_QUEUE_ARN=$(awslocal sqs get-queue-attributes --queue-url $WRITE_FAILURES_QUEUE_URL --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)

awslocal sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:000000000000:QuizzesWriteFailures \
    --protocol sqs \
    --notification-endpoint $WRITE_FAILURES_QUEUE_ARN \
    --output text

awslocal lambda create-event-source-mapping \
    --function-name RetryQuizzesWritesFunction \
    --batch-size 10 \
    --event-source-arn $WRITE_FAILURES_QUEUE_ARN \
    --enabled \
    --output text

# Cleanup
rm *.zip
