import json
import boto3
import random

def lambda_handler(event, context):
    try:
        quiz_data = json.loads(event['body'])
        title = quiz_data['Title']
        questions = quiz_data['Questions']
        visibility = quiz_data.get('Visibility', 'Private')
        if visibility not in ('Public', 'Private'):
            raise ValueError("Visibility must be 'Public' or 'Private'")
    except (KeyError, json.JSONDecodeError, ValueError) as e:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'message': 'Invalid input data',
                'error': str(e)
            })
        }

    for question in questions:
        if not all(k in question for k in ('QuestionText', 'Options', 'CorrectAnswer', 'Trivia')):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': 'Each question must contain QuestionText, Options, CorrectAnswer, and Trivia'
                })
            }

    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('Quizzes')

    quiz_id = str(random.randint(100000, 999999))
    quiz_data['QuizID'] = quiz_id
    quiz_data['Visibility'] = visibility

    table.put_item(Item=quiz_data)

    return {
        'statusCode': 200,
        'body': json.dumps({'QuizID': quiz_id})
    }
