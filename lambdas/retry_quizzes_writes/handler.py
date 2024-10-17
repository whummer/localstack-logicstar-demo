import json
import boto3
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    
    for record in event['Records']:
        try:
            # Parse the SQS message body (SNS notification)
            sns_notification = json.loads(record['body'])
            message = json.loads(sns_notification['Message'])
            
            # Get table name and item from the message
            table_name = message['TableName']
            item = message['Item']
            
            # Try to write to DynamoDB
            table = dynamodb.Table(table_name)
            table.put_item(Item=item)
            print(f"Successfully wrote item to {table_name}: {item.get('QuizID')}")
            
        except ClientError as e:
            print(f"DynamoDB service error, message will be retried: {str(e)}")
            raise e
        except Exception as e:
            print(f"Error processing message: {str(e)}")
            raise e
            
    return {
        'statusCode': 200,
        'body': json.dumps('Processed messages')
    }
