import json
import boto3
import uuid

def lambda_handler(event, context):
    try:
        quiz_data = json.loads(event['body'])
        title = quiz_data['Title']
        questions = quiz_data['Questions']
    except (KeyError, json.JSONDecodeError) as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Invalid input data', 'error': str(e)})
        }

    for question in questions:
        if not all(k in question for k in ('QuestionText', 'Options', 'CorrectAnswer', 'Trivia')):
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Each question must contain QuestionText, Options, CorrectAnswer, and Trivia'})
            }

    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('Quizzes')
    quiz_id = str(uuid.uuid4())
    quiz_data['QuizID'] = quiz_id

    table.put_item(Item=quiz_data)

    return {
        'statusCode': 200,
        'body': json.dumps({'QuizID': quiz_id})
    }
