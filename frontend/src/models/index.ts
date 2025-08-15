export interface User {
  id: string;
  email: string;
  name: string;
  registrationDate: string;
  settings: {
    theme: 'light' | 'dark';
  };
}

export interface Workspace {
  id: string;
  userId: string;
  name: string;
  order: number;
  createdAt: string;
  updatedAt: string;
}

export interface Card {
  id: string;
  workspaceId: string;
  userId: string;
  title: string;
  titleColor: string;
  description: string;
  descriptionColor: string;
  content: string;
  backgroundColor: string;
  position: {
    x: number;
    y: number;
  };
  createdAt: string;
  updatedAt: string;
}

export interface AuthResponse {
  token: string;
  user: User;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterCredentials {
  email: string;
  password: string;
  confirmPassword: string;
  name: string;
}
