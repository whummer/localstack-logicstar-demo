import json
import boto3
import uuid

def lambda_handler(event, context):
    try:
        submission = json.loads(event['body'])
        username = submission['Username']
        quiz_id = submission['QuizID']
        answers = submission['Answers']
    except (KeyError, json.JSONDecodeError) as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Invalid input data', 'error': str(e)})
        }

    sqs = boto3.client('sqs')
    queue_url = sqs.get_queue_url(QueueName='QuizSubmissionQueue')['QueueUrl']
    
    message_body = {
        'SubmissionID': str(uuid.uuid4()),
        'Username': username,
        'QuizID': quiz_id,
        'Answers': answers
    }

    sqs.send_message(
        QueueUrl=queue_url,
        MessageBody=json.dumps(message_body)
    )

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Submission received', 'SubmissionID': message_body['SubmissionID']})
    }
