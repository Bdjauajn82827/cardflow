import api from './api';
import { Card } from '../models';

export const cardService = {
  getCards: async (workspaceId: string): Promise<Card[]> => {
    const response = await api.get<{ cards: Card[] }>(`/cards/workspace/${workspaceId}`);
    return response.data.cards;
  },

  getCard: async (id: string): Promise<Card> => {
    const response = await api.get<{ card: Card }>(`/cards/${id}`);
    return response.data.card;
  },

  createCard: async (card: Omit<Card, 'id' | 'userId' | 'createdAt' | 'updatedAt'>): Promise<Card> => {
    const response = await api.post<{ card: Card }>('/cards', card);
    return response.data.card;
  },

  updateCard: async (id: string, card: Partial<Omit<Card, 'id' | 'userId' | 'createdAt' | 'updatedAt'>>): Promise<Card> => {
    const response = await api.put<{ card: Card }>(`/cards/${id}`, card);
    return response.data.card;
  },

  deleteCard: async (id: string): Promise<void> => {
    await api.delete(`/cards/${id}`);
  },

  updateCardPosition: async (id: string, position: { x: number; y: number }): Promise<Card> => {
    const response = await api.patch<{ card: Card }>(`/cards/${id}/position`, { position });
    return response.data.card;
  },
};
