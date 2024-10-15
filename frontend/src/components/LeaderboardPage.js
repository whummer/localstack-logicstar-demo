import React, { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Container, Typography, List, ListItem, ListItemText } from '@mui/material';

function LeaderboardPage() {
  const { state } = useLocation();
  const navigate = useNavigate();
  const { quizID } = state || {};
  const [leaderboardData, setLeaderboardData] = useState([]);

  useEffect(() => {
    if (!quizID) {
      navigate('/');
      return;
    }

    fetch(`${process.env.REACT_APP_API_ENDPOINT}/getleaderboard?quiz_id=${quizID}&top=10`)
    .then((res) => res.json())
    .then((data) => setLeaderboardData(data))
    .catch((err) => console.error(err));
  }, [quizID, navigate]);

  return (
    <Container maxWidth="sm">
      <Typography variant="h4" gutterBottom>
        Leaderboard
      </Typography>
      {leaderboardData.length > 0 ? (
        <List>
          {leaderboardData.map((entry, index) => (
            <ListItem key={index}>
              <ListItemText
                primary={`${index + 1}. ${entry.Username}`}
                secondary={`Score: ${entry.Score}`}
              />
            </ListItem>
          ))}
        </List>
      ) : (
        <Typography>No entries yet. Be the first to take the quiz!</Typography>
      )}
    </Container>
  );
}

export default LeaderboardPage;
