import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { styled, ThemeProvider } from 'styled-components';
import { RootState } from '../../store';
import { fetchWorkspacesStart, fetchWorkspacesSuccess, fetchWorkspacesFailure, setActiveWorkspace } from '../../store/slices/workspaceSlice';
import { fetchCardsStart, fetchCardsSuccess, fetchCardsFailure, setActiveCard } from '../../store/slices/cardSlice';
import { workspaceService } from '../../services/workspaceService';
import { cardService } from '../../services/cardService';
import { lightTheme, darkTheme } from '../../styles/theme';
import Sidebar from './Sidebar';
import CardGrid from './CardGrid';
import CardModal from './CardModal';
import ProfileModal from './ProfileModal';
import { Card as CardType } from '../../models';

const MainContainer = styled.div`
  display: flex;
  height: 100vh;
  overflow: hidden;
  background: ${({ theme }) => theme.background};
`;

const ContentArea = styled.div`
  flex: 1;
  padding: 24px;
  overflow-y: auto;
  max-width: calc(100vw - 80px);
`;

const Main: React.FC = () => {
  const dispatch = useDispatch();
  const { workspaces, activeWorkspaceId, loading: workspacesLoading } = useSelector((state: RootState) => state.workspace);
  const { cards, activeCard, loading: cardsLoading } = useSelector((state: RootState) => state.card);
  const [isCardModalOpen, setIsCardModalOpen] = useState(false);
  const [isProfileModalOpen, setIsProfileModalOpen] = useState(false);
  const [editingCard, setEditingCard] = useState<CardType | null>(null);

  // Fetch workspaces on component mount
  useEffect(() => {
    const fetchWorkspaces = async () => {
      try {
        dispatch(fetchWorkspacesStart());
        const workspacesData = await workspaceService.getWorkspaces();
        dispatch(fetchWorkspacesSuccess(workspacesData));
      } catch (error: any) {
        dispatch(fetchWorkspacesFailure(error.message || 'Failed to fetch workspaces'));
      }
    };

    fetchWorkspaces();
  }, [dispatch]);

  // Fetch cards when active workspace changes
  useEffect(() => {
    if (activeWorkspaceId) {
      const fetchCards = async () => {
        try {
          dispatch(fetchCardsStart());
          const cardsData = await cardService.getCards(activeWorkspaceId);
          dispatch(fetchCardsSuccess(cardsData));
        } catch (error: any) {
          dispatch(fetchCardsFailure(error.message || 'Failed to fetch cards'));
        }
      };

      fetchCards();
    }
  }, [activeWorkspaceId, dispatch]);

  const handleWorkspaceChange = (id: string) => {
    dispatch(setActiveWorkspace(id));
  };

  const handleCardClick = (card: CardType) => {
    // Если карточка уже активна, деактивируем ее
    if (activeCard && activeCard.id === card.id) {
      dispatch(setActiveCard(null));
    } else {
      dispatch(setActiveCard(card));
    }
  };

  const handleAddCardClick = () => {
    setEditingCard(null);
    setIsCardModalOpen(true);
  };

  const handleEditCardClick = (card: CardType) => {
    setEditingCard(card);
    setIsCardModalOpen(true);
  };

  const handleCardModalClose = () => {
    setIsCardModalOpen(false);
    setEditingCard(null);
  };

  const handleProfileClick = () => {
    setIsProfileModalOpen(true);
  };

  const handleProfileModalClose = () => {
    setIsProfileModalOpen(false);
  };

  const { mode } = useSelector((state: RootState) => state.theme);
  const theme = mode === 'dark' ? darkTheme : lightTheme;

  return (
    <ThemeProvider theme={theme}>
      <MainContainer>
        <Sidebar
          workspaces={workspaces}
          activeWorkspaceId={activeWorkspaceId}
          onWorkspaceChange={handleWorkspaceChange}
          onAddCardClick={handleAddCardClick}
          onProfileClick={handleProfileClick}
        />
        <ContentArea>
          <CardGrid
            cards={cards}
            loading={cardsLoading}
            activeCard={activeCard}
            onCardClick={handleCardClick}
            onEditCard={handleEditCardClick}
          />
        </ContentArea>

        {isCardModalOpen && (
          <CardModal
            card={editingCard}
            workspaceId={activeWorkspaceId || ''}
            onClose={handleCardModalClose}
          />
        )}

        {isProfileModalOpen && (
          <ProfileModal onClose={handleProfileModalClose} />
        )}
      </MainContainer>
    </ThemeProvider>
  );
};

export default Main;
