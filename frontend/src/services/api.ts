import axios from 'axios';
import { AuthResponse, LoginCredentials, RegisterCredentials } from '../models';

// В продакшене на Vercel используем относительный URL
const isProduction = process.env.NODE_ENV === 'production';
const API_URL = isProduction ? '/api' : (process.env.REACT_APP_API_URL || 'http://localhost:5000/api');

// Create an instance of axios with default config
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add a request interceptor to add the auth token to requests
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Add a response interceptor to handle token expiration
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    if (error.response && error.response.status === 401) {
      // Token expired or invalid
      localStorage.removeItem('token');
      window.location.href = '/auth';
    }
    return Promise.reject(error);
  }
);

// Auth services
export const authService = {
  login: async (credentials: LoginCredentials): Promise<AuthResponse> => {
    const response = await api.post<AuthResponse>('/auth/login', credentials);
    // Всегда сохраняем токен в localStorage для постоянной аутентификации
    localStorage.setItem('token', response.data.token);
    return response.data;
  },

  register: async (credentials: RegisterCredentials): Promise<AuthResponse> => {
    const response = await api.post<AuthResponse>('/auth/register', credentials);
    localStorage.setItem('token', response.data.token);
    return response.data;
  },

  logout: (): void => {
    localStorage.removeItem('token');
  },

  getProfile: async (): Promise<AuthResponse['user']> => {
    const response = await api.get<{ user: AuthResponse['user'] }>('/auth/profile');
    return response.data.user;
  },
};

export default api;
