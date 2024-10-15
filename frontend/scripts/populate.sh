#!/bin/bash

API_NAME="QuizAPI"

API_ID=$(aws apigateway get-rest-apis \
  --endpoint-url=http://localhost:4566 \
  --query "items[?name=='$API_NAME'].id" \
  --output text)

if [ -z "$API_ID" ]; then
  echo "Error: API ID not found."
  exit 1
fi

API_ENDPOINT="http://localhost:4566/restapis/$API_ID/test/_user_request_"

echo "REACT_APP_API_ENDPOINT=$API_ENDPOINT" > .env.local

echo "API endpoint fetched and stored in .env.local"
