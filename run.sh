awslocal lambda update-function-code --function-name ScoringFunction --s3-bucket hot-reload --s3-key "$(pwd)/lambdas/scoring"

awslocal lambda update-function-code --function-name ScoringFunction --code S3Bucket="hot-reload",S3Key="$(pwd)/lambdas/scoring"
