import json
import boto3

def lambda_handler(event, context):
    try:
        quiz_id = event['queryStringParameters']['quiz_id']
    except (KeyError, TypeError) as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'quiz_id is required', 'error': str(e)})
        }

    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('Quizzes')
    response = table.get_item(Key={'QuizID': quiz_id})

    if 'Item' in response:
        quiz = response['Item']
        for question in quiz['Questions']:
            question.pop('CorrectAnswer', None)
        return {
            'statusCode': 200,
            'body': json.dumps(quiz)
        }
    else:
        return {
            'statusCode': 404,
            'body': json.dumps({'message': 'Quiz not found'})
        }
