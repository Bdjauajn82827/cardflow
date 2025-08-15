import React, { useState } from 'react';
import { styled } from 'styled-components';
import { useDispatch } from 'react-redux';
import { Card as CardType } from '../../models';
import { deleteCardStart, deleteCardSuccess, deleteCardFailure } from '../../store/slices/cardSlice';
import { cardService } from '../../services/cardService';

interface CardContainerProps {
  backgroundColor: string;
  isActive: boolean;
}

const CardContainer = styled.div<CardContainerProps>`
  width: 100%;
  aspect-ratio: 1;
  background-color: ${({ backgroundColor }) => backgroundColor};
  border-radius: 16px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  position: relative;
  cursor: pointer;
  overflow: hidden;
  
  ${({ isActive }) => isActive && `
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 80%;
    max-width: 600px;
    height: 70vh;
    aspect-ratio: auto;
    z-index: 100;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
  `}

  &::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    opacity: 0;
    pointer-events: none;
    z-index: 0;
    border-radius: 16px;
    
    ${({ isActive }) => isActive && `
      opacity: 1;
    `}
  }
`;

const CardOverlay = styled.div`
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  z-index: 90;
`;

interface TextProps {
  color: string;
}

const CardTitle = styled.h3<TextProps & { isActive: boolean }>`
  font-size: ${({ isActive }) => isActive ? '24px' : '16px'};
  font-weight: 500;
  color: ${({ color }) => color};
  padding: ${({ isActive }) => isActive ? '24px 24px 16px' : '16px'};
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  position: relative;
  z-index: 1;
  max-height: ${({ isActive }) => isActive ? 'none' : '40px'};
  line-height: 1.2;
`;

const CardDescription = styled.p<TextProps & { isActive: boolean }>`
  font-size: ${({ isActive }) => isActive ? '16px' : '14px'};
  font-weight: 400;
  color: ${({ color }) => color};
  opacity: 0.9;
  padding: ${({ isActive }) => isActive ? '0 24px 16px' : '0 16px 16px'};
  display: -webkit-box;
  -webkit-line-clamp: ${({ isActive }) => isActive ? 'none' : '3'};
  -webkit-box-orient: vertical;
  overflow: hidden;
  position: relative;
  z-index: 1;
`;

const CardContent = styled.div<TextProps & { isActive: boolean }>`
  font-size: 14px;
  font-weight: 400;
  color: ${({ color }) => color};
  padding: 0 24px 24px;
  overflow-y: auto;
  max-height: calc(70vh - 150px);
  position: relative;
  z-index: 1;
  display: ${({ isActive }) => isActive ? 'block' : 'none'};

  /* Стили для содержимого, созданного редактором Quill */
  h1, h2, h3, h4, h5, h6 {
    margin-top: 1em;
    margin-bottom: 0.5em;
  }

  p {
    margin-bottom: 0.8em;
  }

  ul, ol {
    padding-left: 2em;
    margin-bottom: 1em;
  }

  blockquote {
    border-left: 4px solid #ccc;
    margin-bottom: 1em;
    padding-left: 16px;
  }

  code, pre {
    background-color: rgba(0, 0, 0, 0.1);
    border-radius: 3px;
    padding: 0.2em 0.4em;
    font-family: monospace;
  }

  pre {
    padding: 1em;
    overflow-x: auto;
  }
`;

const ActionsBar = styled.div`
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 50px;
  background: rgba(0, 0, 0, 0.1);
  display: flex;
  justify-content: flex-end;
  align-items: center;
  padding: 0 16px;
  z-index: 1;
`;

const ActionButton = styled.button`
  width: 36px;
  height: 36px;
  color: white;
  opacity: 0.8;
  background: transparent;
  border-radius: 50%;
  margin-left: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  
  &:hover {
    opacity: 1;
  }
`;

interface CardProps {
  card: CardType;
  isActive: boolean;
  onClick: () => void;
  onEdit: () => void;
}

const Card: React.FC<CardProps> = ({ card, isActive, onClick, onEdit }) => {
  const dispatch = useDispatch();
  const [isDeleting, setIsDeleting] = useState(false);

  const handleDelete = async (e: React.MouseEvent) => {
    e.stopPropagation();
    
    if (isDeleting) return;
    
    const confirmed = window.confirm('Вы уверены, что хотите удалить эту карточку?');
    if (!confirmed) return;
    
    try {
      setIsDeleting(true);
      dispatch(deleteCardStart());
      await cardService.deleteCard(card.id);
      dispatch(deleteCardSuccess(card.id));
    } catch (error: any) {
      dispatch(deleteCardFailure(error.message || 'Failed to delete card'));
    } finally {
      setIsDeleting(false);
    }
  };

  const handleEdit = (e: React.MouseEvent) => {
    e.stopPropagation();
    onEdit();
  };

  const handleClose = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (isActive) {
      onClick(); // Вызываем функцию onClick, которая должна сбросить активную карточку
    }
  };

  return (
    <>
      {isActive && <CardOverlay />}
      
      <CardContainer
        backgroundColor={card.backgroundColor}
        isActive={isActive}
        onClick={onClick}
      >
        <CardTitle
          color={card.titleColor}
          isActive={isActive}
        >
          {card.title}
        </CardTitle>
        
        <CardDescription
          color={card.descriptionColor}
          isActive={isActive}
        >
          {card.description}
        </CardDescription>
        
        <CardContent
          color="#FFFFFF"
          isActive={isActive}
          dangerouslySetInnerHTML={{ __html: card.content }}
        />
        
        {isActive && (
          <ActionsBar>
            <ActionButton onClick={handleDelete} disabled={isDeleting}>
              <span className="mdi mdi-delete"></span>
            </ActionButton>
            
            <ActionButton onClick={handleEdit}>
              <span className="mdi mdi-pencil"></span>
            </ActionButton>
            
            <ActionButton onClick={(e) => {
              e.stopPropagation();
              if (isActive) {
                handleClose(e);
              }
            }}>
              <span className="mdi mdi-close"></span>
            </ActionButton>
          </ActionsBar>
        )}
      </CardContainer>
    </>
  );
};

export default Card;
