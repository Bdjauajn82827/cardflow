import React from 'react';
import { styled } from 'styled-components';
import { DragDropContext, Droppable, Draggable, DropResult } from 'react-beautiful-dnd';
import { useDispatch } from 'react-redux';
import { Card as CardType } from '../../models';
import { updateCardPosition } from '../../store/slices/cardSlice';
import { cardService } from '../../services/cardService';
import Card from './Card';

const GridContainer = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 16px;
  max-width: 1600px;
  margin: 0 auto;
`;

const LoadingMessage = styled.div`
  text-align: center;
  font-size: 18px;
  color: ${({ theme }) => theme.textSecondary};
  margin: 40px 0;
`;

const EmptyMessage = styled.div`
  text-align: center;
  font-size: 18px;
  color: ${({ theme }) => theme.textSecondary};
  margin: 40px 0;
  
  p {
    margin-bottom: 12px;
  }
`;

interface CardGridProps {
  cards: CardType[];
  loading: boolean;
  activeCard: CardType | null;
  onCardClick: (card: CardType) => void;
  onEditCard: (card: CardType) => void;
}

const CardGrid: React.FC<CardGridProps> = ({
  cards,
  loading,
  activeCard,
  onCardClick,
  onEditCard,
}) => {
  const dispatch = useDispatch();

  const handleDragEnd = async (result: DropResult) => {
    if (!result.destination) return;

    const { draggableId, destination } = result;
    const cardId = draggableId;
    
    // Calculate new position based on destination
    const position = {
      x: destination.index % 5, // Assuming max 5 cards per row
      y: Math.floor(destination.index / 5),
    };

    // Update position in Redux store
    dispatch(updateCardPosition({ id: cardId, position }));

    // Update position in the backend
    try {
      await cardService.updateCardPosition(cardId, position);
    } catch (error) {
      console.error('Failed to update card position:', error);
    }
  };

  if (loading) {
    return <LoadingMessage>Загрузка карточек...</LoadingMessage>;
  }

  if (cards.length === 0) {
    return (
      <EmptyMessage>
        <p>Нет карточек в этом рабочем пространстве</p>
        <p>Нажмите кнопку "+" в боковом меню, чтобы создать карточку</p>
      </EmptyMessage>
    );
  }

  return (
    <DragDropContext onDragEnd={handleDragEnd}>
      <Droppable droppableId="cards" direction="horizontal">
        {(provided) => (
          <GridContainer
            {...provided.droppableProps}
            ref={provided.innerRef}
          >
            {cards.map((card, index) => (
              <Draggable key={card.id} draggableId={card.id} index={index}>
                {(provided) => (
                  <div
                    ref={provided.innerRef}
                    {...provided.draggableProps}
                    {...provided.dragHandleProps}
                  >
                    <Card
                      card={card}
                      isActive={activeCard?.id === card.id}
                      onClick={() => onCardClick(card)}
                      onEdit={() => onEditCard(card)}
                    />
                  </div>
                )}
              </Draggable>
            ))}
            {provided.placeholder}
          </GridContainer>
        )}
      </Droppable>
    </DragDropContext>
  );
};

export default CardGrid;
