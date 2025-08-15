import { createGlobalStyle } from 'styled-components';

export const GlobalStyles = createGlobalStyle`
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }

  body {
    font-family: 'Roboto', sans-serif;
    background-color: ${({ theme }) => theme.background};
    color: ${({ theme }) => theme.text};
    transition: all 0.2s linear;
  }

  button {
    font-family: 'Roboto', sans-serif;
    cursor: pointer;
    border: none;
    outline: none;
  }

  input, textarea {
    font-family: 'Roboto', sans-serif;
    outline: none;
  }

  a {
    text-decoration: none;
    color: inherit;
  }
`;
