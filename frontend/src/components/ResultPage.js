// ResultPage.js
import React, { useEffect, useState, useRef } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import {
  Container,
  Typography,
  Button,
  CircularProgress,
  Box,
  Alert,
} from '@mui/material';

function ResultPage() {
  const { state } = useLocation();
  const navigate = useNavigate();
  const { submissionID, quizID } = state || {};
  const [resultData, setResultData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const attemptsRef = useRef(0);
  const maxAttempts = 10;
  const pollingInterval = 3000;
  const timeoutIdRef = useRef(null);

  useEffect(() => {
    if (!submissionID || !quizID) {
      navigate('/');
      return;
    }

    const fetchResult = () => {
      fetch(`${process.env.REACT_APP_API_ENDPOINT}/getsubmission?submission_id=${submissionID}`)
        .then((res) => {
          if (!res.ok) {
            throw new Error('Result not ready yet.');
          }
          return res.json();
        })
        .then((data) => {
          setResultData(data);
          setLoading(false);
        })
        .catch((err) => {
          console.error('Error fetching result:', err);
          attemptsRef.current += 1;
          if (attemptsRef.current >= maxAttempts) {
            setError('Failed to fetch results. Please try again later.');
            setLoading(false);
          } else {
            // Schedule the next fetch
            timeoutIdRef.current = setTimeout(fetchResult, pollingInterval);
          }
        });
    };
    fetchResult();
    return () => {
      if (timeoutIdRef.current) {
        clearTimeout(timeoutIdRef.current);
      }
    };
  }, [submissionID, quizID, navigate]);

  const handleViewLeaderboard = () => {
    navigate('/leaderboard', { state: { quizID } });
  };

  const handleGoHome = () => {
    navigate('/');
  };

  if (loading) {
    return (
      <Container maxWidth="sm" sx={{ textAlign: 'center', marginTop: 8 }}>
        <CircularProgress />
        <Typography variant="h6" sx={{ marginTop: 2 }}>
          Processing your submission...
        </Typography>
      </Container>
    );
  }

  if (error) {
    return (
      <Container maxWidth="sm" sx={{ textAlign: 'center', marginTop: 8 }}>
        <Alert severity="error" sx={{ marginBottom: 2 }}>
          {error}
        </Alert>
        <Button variant="contained" color="primary" onClick={handleGoHome}>
          Go to Home
        </Button>
      </Container>
    );
  }

  return (
    <Container maxWidth="sm">
      <Box sx={{ textAlign: 'center', marginTop: 4 }}>
        <Typography variant="h4" gutterBottom>
          Quiz Results
        </Typography>
        <Typography variant="h6" gutterBottom>
          Score: {resultData.Score} / {resultData.TotalQuestions}
        </Typography>
        <Typography variant="body1" gutterBottom>
          Submission ID: {resultData.SubmissionID}
        </Typography>
        <Box sx={{ marginTop: 4 }}>
          <Button
            variant="contained"
            color="primary"
            onClick={handleViewLeaderboard}
            sx={{ marginRight: 2 }}
          >
            View Leaderboard
          </Button>
          <Button variant="outlined" color="secondary" onClick={handleGoHome}>
            Go to Home
          </Button>
        </Box>
      </Box>
    </Container>
  );
}

export default ResultPage;
