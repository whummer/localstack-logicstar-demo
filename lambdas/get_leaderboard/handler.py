import json
import boto3
from boto3.dynamodb.conditions import Key
from typing import Any, Dict

# Common CORS headers used for API Gateway responses
CORS_HEADERS: Dict[str, str] = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': '*',
}


def _build_response(status_code: int, body: Any) -> Dict[str, Any]:
    """Build a standard API Gateway response with CORS headers and JSON body.

    Keeps response shape identical to previous implementation.
    """
    return {
        'statusCode': status_code,
        'headers': CORS_HEADERS,
        'body': json.dumps(body),
    }

def lambda_handler(event, context):
    try:
        quiz_id = event['queryStringParameters']['quiz_id']
        top = int(event['queryStringParameters'].get('top', 10))
    except (KeyError, TypeError, ValueError) as e:
        return _build_response(400, {'message': 'quiz_id is required and top should be an integer', 'error': str(e)})

    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('UserSubmissions')

    try:
        response = table.query(
            IndexName='QuizID-Score-index',
            KeyConditionExpression=Key('QuizID').eq(quiz_id),
            ScanIndexForward=False,
            Limit=top
        )
        items = response.get('Items', [])
        leaderboard = [
            {
                'Username': item['Username'],
                'Score': float(item['Score']),
                'SubmissionID': item['SubmissionID']
            } for item in items
        ]
        return _build_response(200, leaderboard)
    except Exception as e:
        return _build_response(500, {'message': 'Error retrieving leaderboard', 'error': str(e)})
