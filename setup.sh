#!/bin/bash

awslocal dynamodb create-table \
    --table-name Quizzes \
    --attribute-definitions AttributeName=QuizID,AttributeType=S \
    --key-schema AttributeName=QuizID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

awslocal dynamodb create-table \
    --table-name UserSubmissions \
    --attribute-definitions AttributeName=SubmissionID,AttributeType=S \
    --key-schema AttributeName=SubmissionID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

awslocal sqs create-queue --queue-name QuizSubmissionQueue

# Package functions

zip get_quiz_function.zip get_quiz_function.py
zip create_quiz_function.zip create_quiz_function.py
zip submit_quiz_function.zip submit_quiz_function.py
zip scoring_function.zip scoring_function.py

# Deploy Lambdas

# GetQuizFunction
awslocal lambda create-function \
    --function-name GetQuizFunction \
    --runtime python3.8 \
    --handler get_quiz_function.lambda_handler \
    --zip-file fileb://get_quiz_function.zip \
    --role arn:aws:iam::000000000000:role/DummyRole

# CreateQuizFunction
awslocal lambda create-function \
    --function-name CreateQuizFunction \
    --runtime python3.8 \
    --handler create_quiz_function.lambda_handler \
    --zip-file fileb://create_quiz_function.zip \
    --role arn:aws:iam::000000000000:role/DummyRole

# SubmitQuizFunction
awslocal lambda create-function \
    --function-name SubmitQuizFunction \
    --runtime python3.8 \
    --handler submit_quiz_function.lambda_handler \
    --zip-file fileb://submit_quiz_function.zip \
    --role arn:aws:iam::000000000000:role/DummyRole

# ScoringFunction
awslocal lambda create-function \
    --function-name ScoringFunction \
    --runtime python3.8 \
    --handler scoring_function.lambda_handler \
    --zip-file fileb://scoring_function.zip \
    --role arn:aws:iam::000000000000:role/DummyRole

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

# Deploy

awslocal apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name test

# Get the ID and add it here

API_ENDPOINT="http://localhost:4566/restapis/$API_ID/test/_user_request_"

# Testing

# Create a quiz

curl -X POST "$API_ENDPOINT/createquiz" \
-H "Content-Type: application/json" \
-d '{
    "Title": "Sample Quiz",
    "Questions": [
        {
            "QuestionText": "What is the capital of France?",
            "Options": ["A. Berlin", "B. London", "C. Madrid", "D. Paris"],
            "CorrectAnswer": "D. Paris",
            "Trivia": "Paris is known as the City of Light."
        },
        {
            "QuestionText": "Who wrote Hamlet?",
            "Options": ["A. Dickens", "B. Shakespeare", "C. Twain", "D. Hemingway"],
            "CorrectAnswer": "B. Shakespeare",
            "Trivia": "Shakespeare is often called England national poet."
        }
    ]
}'

# Get the quiz; Change the ID below

curl -X GET "$API_ENDPOINT/getquiz?quiz_id=895cdc2c-89f5-4b8e-9eee-e2ccfaab4ac3"

# Submit response

curl -X POST "$API_ENDPOINT/submitquiz" \
-H "Content-Type: application/json" \
-d '{
    "Username": "john_doe",
    "QuizID": "895cdc2c-89f5-4b8e-9eee-e2ccfaab4ac3",
    "Answers": {
        "0": "D",
        "1": "B"
    }
}'

# Get the response

awslocal dynamodb get-item \
    --table-name UserSubmissions \
    --key '{"SubmissionID": {"S": "96dc8c43-039a-45a7-a813-8031e2800f86"}}'
