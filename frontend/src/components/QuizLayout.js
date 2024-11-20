import React from 'react';
import { Container, Box } from '@mui/material';
import QuizLogo from '../../src/QuizLogo.svg';

function QuizLayout({ children }) {
  return (
    <Box>
      <img src={QuizLogo} alt="" className="quiz-header-img" />
      <Container>{children}</Container>
    </Box>
  );
}

export default QuizLayout;
