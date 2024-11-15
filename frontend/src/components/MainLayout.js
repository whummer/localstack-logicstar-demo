import React from 'react';
import { Typography, Container, Box } from '@mui/material';

function MainLayout({ children }) {
  return (
    <Box>
      <img
        src="/Quiz-Show-Logo.png"
        alt="AWSome Quiz Show"
        className="main-header-img"
      />
      <Container>{children}</Container>
      <Box component="footer" sx={{ p: 2, mt: 'auto', textAlign: 'center' }}>
        <Typography variant="body2" color="textSecondary">
          &copy; 2023 My Website
        </Typography>
      </Box>
    </Box>
  );
}

export default MainLayout;
