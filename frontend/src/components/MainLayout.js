import React from 'react';
import { Container, Box } from '@mui/material';
import MainLogo from '../../src/MainLogo.svg';

function MainLayout({ children }) {
  return (
    <Box>
      <img src={MainLogo} alt="AWSome Quiz Show" className="main-header-img" />
      <Container>{children}</Container>
    </Box>
  );
}

export default MainLayout;
