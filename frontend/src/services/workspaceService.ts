import api from './api';
import { Workspace } from '../models';

export const workspaceService = {
  getWorkspaces: async (): Promise<Workspace[]> => {
    const response = await api.get<{ workspaces: Workspace[] }>('/workspaces');
    return response.data.workspaces;
  },

  getWorkspace: async (id: string): Promise<Workspace> => {
    const response = await api.get<{ workspace: Workspace }>(`/workspaces/${id}`);
    return response.data.workspace;
  },

  createWorkspace: async (workspace: Pick<Workspace, 'name' | 'order'>): Promise<Workspace> => {
    const response = await api.post<{ workspace: Workspace }>('/workspaces', workspace);
    return response.data.workspace;
  },

  updateWorkspace: async (id: string, workspace: Partial<Pick<Workspace, 'name' | 'order'>>): Promise<Workspace> => {
    const response = await api.put<{ workspace: Workspace }>(`/workspaces/${id}`, workspace);
    return response.data.workspace;
  },

  deleteWorkspace: async (id: string): Promise<void> => {
    await api.delete(`/workspaces/${id}`);
  },
};
