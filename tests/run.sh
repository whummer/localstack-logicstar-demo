# Create a quiz

curl -X POST "$API_ENDPOINT/createquiz" \
-H "Content-Type: application/json" \
-d '{
    "Title": "Sample Quiz",
    "Visibility": "Public",
    "Questions": [
        {
            "QuestionText": "What is the capital of France?",
            "Options": ["A. Berlin", "B. London", "C. Madrid", "D. Paris"],
            "CorrectAnswer": "D. Paris",
            "Trivia": "Paris is known as the City of Light."
        },
        {
            "QuestionText": "Who wrote Hamlet?",
            "Options": ["A. Dickens", "B. Shakespeare", "C. Twain", "D. Hemingway"],
            "CorrectAnswer": "B. Shakespeare",
            "Trivia": "Shakespeare is often called England national poet."
        }
    ]
}'

# Get the quiz; Change the ID below

curl -X GET "$API_ENDPOINT/getquiz?quiz_id=195167"

# Submit responses

curl -X POST "$API_ENDPOINT/submitquiz" \
-H "Content-Type: application/json" \
-d '{
    "Username": "user1",
    "QuizID": "195167",
    "Answers": {
        "0": "D. Paris",
        "1": "B. Shakespeare"
    }
}'


curl -X POST "$API_ENDPOINT/submitquiz" \
-H "Content-Type: application/json" \
-d '{
    "Username": "user2",
    "Email": "user@example.com",
    "QuizID": "195167",
    "Answers": {
        "0": "D. Paris",
        "1": "B. Shakespeare"
    }
}'

curl -X POST "$API_ENDPOINT/submitquiz" \
-H "Content-Type: application/json" \
-d '{
    "Username": "user3",
    "QuizID": "195167",
    "Answers": {
        "0": "D. Paris",
        "1": "D. Hemingway"
    }
}'

# Get submission

curl -X GET "$API_ENDPOINT/getsubmission?submission_id=ed6f3128-20c3-45ce-847f-661bc7301962"

# Get leaderboard

curl -X GET "$API_ENDPOINT/getleaderboard?quiz_id=195167&top=3"

# Check SES
curl -s http://localhost.localstack.cloud:4566/_aws/ses
