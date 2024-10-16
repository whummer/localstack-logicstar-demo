// QuizPage.js
import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import {
  Container,
  Typography,
  RadioGroup,
  FormControlLabel,
  Radio,
  Button,
  CircularProgress,
  Box,
} from '@mui/material';

function QuizPage() {
  const { state } = useLocation();
  const navigate = useNavigate();
  const { quizID, username, email } = state || {};
  const [quizData, setQuizData] = useState(null);
  const [answers, setAnswers] = useState({});
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!quizID || !username) {
      navigate('/');
      return;
    }

    fetch(`${process.env.REACT_APP_API_ENDPOINT}/getquiz?quiz_id=${quizID}`)
      .then((res) => res.json())
      .then((data) => setQuizData(data))
      .catch((err) => console.error(err));
  }, [quizID, username, navigate]);

  const handleOptionChange = (questionIndex, option) => {
    setAnswers({ ...answers, [questionIndex]: option });
  };

  const handleSubmit = () => {
    const submissionData = {
      Username: username,
      QuizID: quizID,
      Answers: answers,
    };
    if (email) {
      submissionData.Email = email;
    }

    setSubmitting(true); // Start submitting

    fetch(`${process.env.REACT_APP_API_ENDPOINT}/submitquiz`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(submissionData),
    })
      .then((res) => res.json())
      .then((data) => {
        setSubmitting(false); // Submission complete
        navigate('/result', {
          state: { submissionID: data.SubmissionID, quizID },
        });
      })
      .catch((err) => {
        console.error(err);
        setSubmitting(false);
        alert('Failed to submit quiz. Please try again.');
      });
  };

  if (!quizData) {
    return (
      <Container maxWidth="md" sx={{ textAlign: 'center', marginTop: 8 }}>
        <CircularProgress />
        <Typography variant="h6" sx={{ marginTop: 2 }}>
          Loading quiz...
        </Typography>
      </Container>
    );
  }

  return (
    <Container maxWidth="md">
      <Typography variant="h4" gutterBottom>
        {quizData.Title}
      </Typography>
      {quizData.Questions.map((question, index) => (
        <div key={index}>
          <Typography variant="h6">
            {index + 1}. {question.QuestionText}
          </Typography>
          <RadioGroup
            name={`question-${index}`}
            value={answers[index] || ''}
            onChange={(e) => handleOptionChange(index, e.target.value)}
          >
            {question.Options.map((option, idx) => (
              <FormControlLabel
                key={idx}
                value={option}
                control={<Radio />}
                label={option}
              />
            ))}
          </RadioGroup>
        </div>
      ))}
      {submitting ? (
        <Box sx={{ textAlign: 'center', marginTop: 4 }}>
          <CircularProgress />
          <Typography variant="h6" sx={{ marginTop: 2 }}>
            Submitting your answers...
          </Typography>
        </Box>
      ) : (
        <Button
          variant="contained"
          color="primary"
          onClick={handleSubmit}
          disabled={Object.keys(answers).length !== quizData.Questions.length}
          sx={{ marginTop: 4 }}
        >
          Submit
        </Button>
      )}
    </Container>
  );
}

export default QuizPage;
