import json
import boto3
from decimal import Decimal

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    quizzes_table = dynamodb.Table('Quizzes')
    submissions_table = dynamodb.Table('UserSubmissions')

    for record in event['Records']:
        message_body = json.loads(record['body'])
        submission_id = message_body['SubmissionID']
        username = message_body['Username']
        quiz_id = message_body['QuizID']
        user_answers = message_body['Answers']

        if not all([submission_id, username, quiz_id, user_answers]):
            continue

        response = quizzes_table.get_item(Key={'QuizID': quiz_id})
        if 'Item' not in response:
            continue

        quiz = response['Item']
        correct_answers = [q['CorrectAnswer'] for q in quiz['Questions']]
        total_questions = len(correct_answers)

        score = sum(
            1 for idx, correct in enumerate(correct_answers)
            if str(user_answers.get(str(idx))) == str(correct)
        )

        submissions_table.put_item(Item={
            'SubmissionID': submission_id,
            'Username': username,
            'QuizID': quiz_id,
            'UserAnswers': user_answers,
            'Score': Decimal(score),
            'TotalQuestions': Decimal(total_questions)
        })
