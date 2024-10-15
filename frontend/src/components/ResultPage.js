// ResultPage.js
import React, { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Container, Typography, Button } from '@mui/material';

function ResultPage() {
  const { state } = useLocation();
  const navigate = useNavigate();
  const { submissionID, quizID } = state || {};
  const [resultData, setResultData] = useState(null);

  useEffect(() => {
    if (!submissionID || !quizID) {
      navigate('/');
      return;
    }

    fetch(`${process.env.REACT_APP_API_ENDPOINT}/getsubmission?submission_id=${submissionID}`)
    .then((res) => res.json())
    .then((data) => setResultData(data))
    .catch((err) => console.error(err));
  }, [submissionID, quizID, navigate]);

  const handleViewLeaderboard = () => {
    navigate('/leaderboard', { state: { quizID } });
  };

  if (!resultData) {
    return <Typography>Loading...</Typography>;
  }

  return (
    <Container maxWidth="sm">
      <Typography variant="h4" gutterBottom>
        Quiz Results
      </Typography>
      <Typography variant="h6">
        Score: {resultData.Score} / {resultData.TotalQuestions}
      </Typography>
      <Typography variant="body1">
        Submission ID: {resultData.SubmissionID}
      </Typography>
      <Button variant="contained" color="primary" onClick={handleViewLeaderboard}>
        View Leaderboard
      </Button>
    </Container>
  );
}

export default ResultPage;
