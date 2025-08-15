import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { Card } from '../../models';

interface CardState {
  cards: Card[];
  activeCard: Card | null;
  loading: boolean;
  error: string | null;
}

const initialState: CardState = {
  cards: [],
  activeCard: null,
  loading: false,
  error: null,
};

export const cardSlice = createSlice({
  name: 'card',
  initialState,
  reducers: {
    fetchCardsStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    fetchCardsSuccess: (state, action: PayloadAction<Card[]>) => {
      state.cards = action.payload;
      state.loading = false;
    },
    fetchCardsFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    setActiveCard: (state, action: PayloadAction<Card | null>) => {
      state.activeCard = action.payload;
    },
    addCardStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    addCardSuccess: (state, action: PayloadAction<Card>) => {
      state.cards.push(action.payload);
      state.loading = false;
    },
    addCardFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    updateCardStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    updateCardSuccess: (state, action: PayloadAction<Card>) => {
      const index = state.cards.findIndex((card) => card.id === action.payload.id);
      if (index !== -1) {
        state.cards[index] = action.payload;
      }
      // Update active card if it was the one updated
      if (state.activeCard && state.activeCard.id === action.payload.id) {
        state.activeCard = action.payload;
      }
      state.loading = false;
    },
    updateCardFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    deleteCardStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    deleteCardSuccess: (state, action: PayloadAction<string>) => {
      state.cards = state.cards.filter((card) => card.id !== action.payload);
      // Reset active card if it was the one deleted
      if (state.activeCard && state.activeCard.id === action.payload) {
        state.activeCard = null;
      }
      state.loading = false;
    },
    deleteCardFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    updateCardPosition: (state, action: PayloadAction<{ id: string; position: { x: number; y: number } }>) => {
      const card = state.cards.find((card) => card.id === action.payload.id);
      if (card) {
        card.position = action.payload.position;
      }
    },
    clearCardError: (state) => {
      state.error = null;
    },
  },
});

export const {
  fetchCardsStart,
  fetchCardsSuccess,
  fetchCardsFailure,
  setActiveCard,
  addCardStart,
  addCardSuccess,
  addCardFailure,
  updateCardStart,
  updateCardSuccess,
  updateCardFailure,
  deleteCardStart,
  deleteCardSuccess,
  deleteCardFailure,
  updateCardPosition,
  clearCardError,
} = cardSlice.actions;

export default cardSlice.reducer;
