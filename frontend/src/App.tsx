import React, { useEffect, useState } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useSelector, useDispatch } from 'react-redux';
import { RootState } from './store';
import { setTheme } from './store/slices/themeSlice';
import { loginSuccess } from './store/slices/authSlice';
import Auth from './pages/Auth';
import Main from './pages/Main';
import ProtectedRoute from './components/ProtectedRoute';
import { authService } from './services/api';

const App: React.FC = () => {
  const dispatch = useDispatch();
  const { isAuthenticated } = useSelector((state: RootState) => state.auth);
  const [isLoading, setIsLoading] = useState(true);
  
  useEffect(() => {
    // Check for saved theme preference
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme && (savedTheme === 'light' || savedTheme === 'dark')) {
      dispatch(setTheme(savedTheme as 'light' | 'dark'));
    }
    
    // Check if user is already authenticated
    const checkAuth = async () => {
      try {
        const token = localStorage.getItem('token');
        if (token) {
          // Verify token by getting user profile
          const user = await authService.getProfile();
          dispatch(loginSuccess({ user }));
        }
      } catch (error) {
        // Token is invalid, it will be removed by the interceptor
        console.error("Authentication error:", error);
      } finally {
        setIsLoading(false);
      }
    };
    
    checkAuth();
  }, [dispatch]);

  return (
    <>
      {isLoading ? (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
          Загрузка...
        </div>
      ) : (
        <Routes>
          <Route path="/auth" element={!isAuthenticated ? <Auth /> : <Navigate to="/" />} />
          <Route path="/" element={
            <ProtectedRoute isAuthenticated={isAuthenticated}>
              <Main />
            </ProtectedRoute>
          } />
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
      )}
    </>
  );
};

export default App;
