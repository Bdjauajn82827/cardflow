import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { styled, ThemeProvider } from 'styled-components';
import { Formik, Form, Field, ErrorMessage } from 'formik';
import * as Yup from 'yup';
import { RootState } from '../../store';
import { 
  loginStart, 
  loginSuccess, 
  loginFailure,
  registerStart,
  registerSuccess,
  registerFailure,
  clearError
} from '../../store/slices/authSlice';
import { authService } from '../../services/api';
import { lightTheme, darkTheme } from '../../styles/theme';

const AuthContainer = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: ${({ theme }) => theme.background};
  position: relative;
  overflow: hidden;
  
  &::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: ${({ theme }) => `repeating-linear-gradient(
      45deg,
      ${theme.background},
      ${theme.background} 10px,
      ${theme.surface} 10px,
      ${theme.surface} 20px
    )`};
    opacity: 0.05;
    z-index: 0;
  }
`;

const AuthForm = styled.div`
  width: 400px;
  background: ${({ theme }) => theme.surface};
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  padding: 32px;
  z-index: 1;
  position: relative;
`;

const FormTitle = styled.h1`
  font-size: 24px;
  font-weight: 500;
  color: ${({ theme }) => theme.primary};
  text-align: center;
  margin-bottom: 24px;
`;

const FormGroup = styled.div`
  margin-bottom: 16px;
`;

const StyledField = styled(Field)`
  width: 100%;
  height: 48px;
  padding: 12px 16px;
  background: ${({ theme }) => theme.background};
  border: 1px solid transparent;
  border-radius: 8px;
  font-size: 14px;
  color: ${({ theme }) => theme.text};
  transition: all 0.2s ease-in-out;
  
  &:focus {
    border-color: ${({ theme }) => theme.primary};
  }
`;

const ErrorText = styled.div`
  color: ${({ theme }) => theme.error};
  font-size: 12px;
  margin-top: 5px;
  margin-left: 5px;
`;

const CheckboxContainer = styled.div`
  display: flex;
  align-items: center;
  margin-top: 16px;
`;

const StyledCheckbox = styled(Field)`
  margin-right: 8px;
  width: 18px;
  height: 18px;
  cursor: pointer;
  
  &:checked {
    accent-color: ${({ theme }) => theme.primary};
  }
`;

const CheckboxLabel = styled.label`
  font-size: 14px;
  color: ${({ theme }) => theme.text};
  cursor: pointer;
`;

const SubmitButton = styled.button`
  width: 100%;
  height: 48px;
  background: ${({ theme }) => theme.primary};
  color: white;
  border-radius: 8px;
  margin-top: 24px;
  font-size: 16px;
  transition: all 0.2s ease-in-out;
  
  &:hover {
    opacity: 0.9;
  }
  
  &:active {
    transform: scale(0.98);
  }
`;

const SwitchModeText = styled.p`
  text-align: center;
  margin-top: 16px;
  font-size: 14px;
  color: ${({ theme }) => theme.textSecondary};
`;

const SwitchModeLink = styled.span`
  color: ${({ theme }) => theme.primary};
  cursor: pointer;
  
  &:hover {
    text-decoration: underline;
  }
`;

const ErrorAlert = styled.div`
  background: rgba(244, 67, 54, 0.1);
  color: ${({ theme }) => theme.error};
  padding: 10px;
  border-radius: 8px;
  margin-bottom: 16px;
  text-align: center;
`;

const loginValidationSchema = Yup.object({
  email: Yup.string()
    .email('Invalid email address')
    .required('Email is required'),
  password: Yup.string()
    .required('Password is required'),
});

const registerValidationSchema = Yup.object({
  email: Yup.string()
    .email('Invalid email address')
    .required('Email is required'),
  password: Yup.string()
    .min(8, 'Password must be at least 8 characters')
    .matches(/(?=.*[0-9])/, 'Password must contain at least one number')
    .matches(/(?=.*[a-zA-Z])/, 'Password must contain at least one letter')
    .required('Password is required'),
  confirmPassword: Yup.string()
    .oneOf([Yup.ref('password'), undefined], 'Passwords must match')
    .required('Confirm password is required'),
  name: Yup.string()
    .required('Name is required'),
});

const Auth: React.FC = () => {
  const [isLoginMode, setIsLoginMode] = useState(true);
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { loading, error } = useSelector((state: RootState) => state.auth);

  const handleSubmit = async (values: any) => {
    if (isLoginMode) {
      try {
        dispatch(loginStart());
        const response = await authService.login({
          email: values.email,
          password: values.password,
        });
        dispatch(loginSuccess({ user: response.user }));
        navigate('/');
      } catch (error: any) {
        dispatch(loginFailure(error.response?.data?.message || 'Login failed'));
      }
    } else {
      try {
        dispatch(registerStart());
        const response = await authService.register({
          email: values.email,
          password: values.password,
          confirmPassword: values.confirmPassword,
          name: values.name,
        });
        dispatch(registerSuccess({ user: response.user }));
        navigate('/');
      } catch (error: any) {
        dispatch(registerFailure(error.response?.data?.message || 'Registration failed'));
      }
    }
  };

  const toggleMode = () => {
    setIsLoginMode(!isLoginMode);
    dispatch(clearError());
  };

  const { mode } = useSelector((state: RootState) => state.theme);
  const theme = mode === 'dark' ? darkTheme : lightTheme;
  
  return (
    <ThemeProvider theme={theme}>
      <AuthContainer>
        <AuthForm>
          <FormTitle>{isLoginMode ? 'Вход в систему' : 'Регистрация'}</FormTitle>
          
          {error && <ErrorAlert>{error}</ErrorAlert>}
          
          <Formik
            initialValues={
              isLoginMode
                ? { email: '', password: '' }
                : { email: '', password: '', confirmPassword: '', name: '' }
            }
            validationSchema={isLoginMode ? loginValidationSchema : registerValidationSchema}
            onSubmit={handleSubmit}
          >
            {({ isSubmitting }) => (
              <Form>
                <FormGroup>
                  <StyledField
                    type="email"
                    name="email"
                    placeholder="Email"
                  />
                  <ErrorMessage name="email" component={ErrorText} />
                </FormGroup>
                
                <FormGroup>
                  <StyledField
                    type="password"
                    name="password"
                    placeholder="Пароль"
                  />
                  <ErrorMessage name="password" component={ErrorText} />
                </FormGroup>
                
                {!isLoginMode && (
                  <>
                    <FormGroup>
                      <StyledField
                        type="password"
                        name="confirmPassword"
                        placeholder="Подтвердите пароль"
                      />
                      <ErrorMessage name="confirmPassword" component={ErrorText} />
                    </FormGroup>
                    
                    <FormGroup>
                      <StyledField
                        type="text"
                        name="name"
                        placeholder="Имя"
                      />
                      <ErrorMessage name="name" component={ErrorText} />
                    </FormGroup>
                  </>
                )}
                
                <SubmitButton type="submit" disabled={isSubmitting || loading}>
                  {isLoginMode ? 'Войти' : 'Зарегистрироваться'}
                </SubmitButton>
              </Form>
            )}
          </Formik>
          
          <SwitchModeText>
            {isLoginMode ? 'Нет аккаунта? ' : 'Уже есть аккаунт? '}
            <SwitchModeLink onClick={toggleMode}>
              {isLoginMode ? 'Зарегистрироваться' : 'Войти'}
            </SwitchModeLink>
          </SwitchModeText>
        </AuthForm>
      </AuthContainer>
    </ThemeProvider>
  );
};

export default Auth;
