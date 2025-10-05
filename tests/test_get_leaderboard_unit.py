import json
from decimal import Decimal


def test_get_leaderboard_returns_200_and_items(monkeypatch):
    # Import the handler module
    from lambdas.get_leaderboard import handler as glh

    # Fake DynamoDB table and resource to avoid external dependencies
    class FakeTable:
        def query(self, **kwargs):
            # Simulate items as written by the scoring lambda
            return {
                'Items': [
                    {
                        'SubmissionID': 'sub-123',
                        'Username': 'user1',
                        'QuizID': 'quiz-abc',
                        'Score': Decimal('42.5'),
                    }
                ]
            }

    class FakeDynamoResource:
        def Table(self, name):
            assert name == 'UserSubmissions'
            return FakeTable()

    class FakeBoto3:
        def resource(self, service_name):
            assert service_name == 'dynamodb'
            return FakeDynamoResource()

    # Patch boto3 within the handler module
    monkeypatch.setattr(glh, 'boto3', FakeBoto3(), raising=False)

    event = {
        'queryStringParameters': {
            'quiz_id': 'quiz-abc',
            'top': '1',
        }
    }

    response = glh.lambda_handler(event, None)

    # With correct key names, this should be 200 and return the leaderboard
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body == [
        {
            'Username': 'user1',
            'Score': 42.5,
            'SubmissionID': 'sub-123',
        }
    ]
