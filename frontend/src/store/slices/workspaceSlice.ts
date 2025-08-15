import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { Workspace } from '../../models';

interface WorkspaceState {
  workspaces: Workspace[];
  activeWorkspaceId: string | null;
  loading: boolean;
  error: string | null;
}

const initialState: WorkspaceState = {
  workspaces: [],
  activeWorkspaceId: null,
  loading: false,
  error: null,
};

export const workspaceSlice = createSlice({
  name: 'workspace',
  initialState,
  reducers: {
    fetchWorkspacesStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    fetchWorkspacesSuccess: (state, action: PayloadAction<Workspace[]>) => {
      state.workspaces = action.payload;
      state.loading = false;
      // Set active workspace to the first one if none is active
      if (!state.activeWorkspaceId && action.payload.length > 0) {
        state.activeWorkspaceId = action.payload[0].id;
      }
    },
    fetchWorkspacesFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    setActiveWorkspace: (state, action: PayloadAction<string>) => {
      state.activeWorkspaceId = action.payload;
    },
    addWorkspaceStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    addWorkspaceSuccess: (state, action: PayloadAction<Workspace>) => {
      state.workspaces.push(action.payload);
      state.loading = false;
    },
    addWorkspaceFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    updateWorkspaceStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    updateWorkspaceSuccess: (state, action: PayloadAction<Workspace>) => {
      const index = state.workspaces.findIndex((workspace) => workspace.id === action.payload.id);
      if (index !== -1) {
        state.workspaces[index] = action.payload;
      }
      state.loading = false;
    },
    updateWorkspaceFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    deleteWorkspaceStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    deleteWorkspaceSuccess: (state, action: PayloadAction<string>) => {
      state.workspaces = state.workspaces.filter(
        (workspace) => workspace.id !== action.payload
      );
      // If active workspace was deleted, set the first available as active
      if (state.activeWorkspaceId === action.payload && state.workspaces.length > 0) {
        state.activeWorkspaceId = state.workspaces[0].id;
      } else if (state.workspaces.length === 0) {
        state.activeWorkspaceId = null;
      }
      state.loading = false;
    },
    deleteWorkspaceFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    clearWorkspaceError: (state) => {
      state.error = null;
    },
  },
});

export const {
  fetchWorkspacesStart,
  fetchWorkspacesSuccess,
  fetchWorkspacesFailure,
  setActiveWorkspace,
  addWorkspaceStart,
  addWorkspaceSuccess,
  addWorkspaceFailure,
  updateWorkspaceStart,
  updateWorkspaceSuccess,
  updateWorkspaceFailure,
  deleteWorkspaceStart,
  deleteWorkspaceSuccess,
  deleteWorkspaceFailure,
  clearWorkspaceError,
} = workspaceSlice.actions;

export default workspaceSlice.reducer;
