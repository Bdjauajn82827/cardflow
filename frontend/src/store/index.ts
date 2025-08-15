import { configureStore } from '@reduxjs/toolkit';
import authReducer from './slices/authSlice';
import themeReducer from './slices/themeSlice';
import workspaceReducer from './slices/workspaceSlice';
import cardReducer from './slices/cardSlice';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    theme: themeReducer,
    workspace: workspaceReducer,
    card: cardReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
