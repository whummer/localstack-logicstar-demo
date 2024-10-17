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

curl -X POST "$API_ENDPOINT/createquiz" \
-H "Content-Type: application/json" \
-d $'{
    "Title": "General Knowledge Quiz",
    "Visibility": "Private",
    "Questions": [
        {
            "QuestionText": "What is the largest planet in our solar system?",
            "Options": ["A. Earth", "B. Mars", "C. Jupiter", "D. Saturn"],
            "CorrectAnswer": "C. Jupiter",
            "Trivia": "Jupiter is so large that all the other planets in the solar system could fit inside it."
        },
        {
            "QuestionText": "Which element has the chemical symbol '\''O'\''?",
            "Options": ["A. Gold", "B. Oxygen", "C. Silver", "D. Iron"],
            "CorrectAnswer": "B. Oxygen",
            "Trivia": "Oxygen makes up about 21% of the Earth'\''s atmosphere."
        },
        {
            "QuestionText": "In which year did World War II end?",
            "Options": ["A. 1943", "B. 1945", "C. 1947", "D. 1950"],
            "CorrectAnswer": "B. 1945",
            "Trivia": "The war ended with the surrender of Japan on September 2, 1945."
        }
    ]
}'

# List Quizzes; Private quiz is not listed

curl -X GET "$API_ENDPOINT/listquizzes"

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

# Chaos

awslocal sqs receive-message --queue-url $WRITE_FAILURES_QUEUE_URL --max-number-of-messages 10 --wait-time-seconds 5

curl -X POST "$API_ENDPOINT/createquiz" \
-H "Content-Type: application/json" \
-d '{
    "Title": "Check Quiz",
    "Visibility": "Public",
    "Questions": [
        {
            "QuestionText": "What is the capital of Spain?",
            "Options": ["A. Lisbon", "B. Madrid", "C. Barcelona", "D. Valencia"],
            "CorrectAnswer": "B. Madrid",
            "Trivia": "Madrid is the capital and largest city of Spain."
        }
    ]
}'
