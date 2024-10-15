// HomePage.js
import React, { useState } from 'react';
import { TextField, Button, Container, Typography } from '@mui/material';
import { useNavigate } from 'react-router-dom';

function HomePage() {
  const [quizID, setQuizID] = useState('');
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const navigate = useNavigate();

  const handleStart = () => {
    navigate('/quiz', { state: { quizID, username, email } });
  };

  return (
    <Container maxWidth="sm">
      <Typography variant="h4" gutterBottom>
        Enter Quiz Details
      </Typography>
      <TextField
        label="Quiz ID"
        fullWidth
        margin="normal"
        value={quizID}
        onChange={(e) => setQuizID(e.target.value)}
      />
      <TextField
        label="Username"
        fullWidth
        margin="normal"
        value={username}
        onChange={(e) => setUsername(e.target.value)}
      />
      <TextField
        label="Email (Optional)"
        fullWidth
        margin="normal"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
      />
      <Button
        variant="contained"
        color="primary"
        onClick={handleStart}
        disabled={!quizID || !username}
      >
        Start Playing
      </Button>
    </Container>
  );
}

export default HomePage;
