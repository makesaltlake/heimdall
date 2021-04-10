import { useEffect } from 'react';

const ExternalRedirect = ({ to }) => {
  useEffect(() => {
    window.location.href = to;
  });

  return null;
};
export default ExternalRedirect;
