import React, { useState, useEffect, useRef } from 'react';
import { styled } from 'styled-components';
import { useDispatch, useSelector } from 'react-redux';
import { Formik, Form, Field, ErrorMessage } from 'formik';
import * as Yup from 'yup';
import { Editor } from '@tinymce/tinymce-react';
import '../../styles/tinymce-override.css';
import { Card } from '../../models';
import { RootState } from '../../store';
import { 
  addCardStart, 
  addCardSuccess, 
  addCardFailure,
  updateCardStart,
  updateCardSuccess,
  updateCardFailure,
  deleteCardSuccess,
  deleteCardFailure
} from '../../store/slices/cardSlice';
import { cardService } from '../../services/cardService';

const ModalOverlay = styled.div`
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
`;

const ModalContainer = styled.div`
  width: 800px;
  max-height: 90vh;
  background: ${({ theme }) => theme.surface};
  border-radius: 16px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
  padding: 24px;
  display: flex;
  flex-direction: column;
  overflow: auto;
`;

const ModalTitle = styled.h2`
  font-size: 22px;
  font-weight: 500;
  color: ${({ theme }) => theme.primary};
  text-align: center;
  margin-bottom: 20px;
`;

const ModalContent = styled.div`
  display: flex;
  margin-bottom: 20px;
`;

const LeftColumn = styled.div`
  width: 220px;
  padding-right: 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
`;

const RightColumn = styled.div`
  flex: 1;
  padding-left: 16px;
  display: flex;
  flex-direction: column;
`;

const CardPreview = styled.div<{ backgroundColor: string }>`
  width: 200px;
  height: 200px;
  background-color: ${({ backgroundColor }) => backgroundColor};
  border-radius: 16px;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  transition: all 0.2s ease-in-out;
`;

const PreviewTitle = styled.div<{ color: string }>`
  font-size: 16px;
  font-weight: 500;
  color: ${({ color }) => color};
  padding: 16px 16px 8px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
`;

// Мы сохраняем оригинальную версию PreviewDescription для обратной совместимости
const PreviewDescription = styled.div<{ color: string }>`
  font-size: 14px;
  font-weight: 400;
  color: ${({ color }) => color};
  opacity: 0.9;
  padding: 0 16px 16px;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
`;

const ColorPalette = styled.div`
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 8px;
  margin-top: 16px;
  width: 100%;
`;

interface ColorButtonProps {
  color: string;
  isSelected: boolean;
}

const ColorButton = styled.button<ColorButtonProps>`
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background-color: ${({ color }) => color};
  border: ${({ isSelected }) => isSelected ? '2px solid white' : 'none'};
  box-shadow: ${({ isSelected }) => isSelected ? '0 0 0 2px #3F51B5' : 'none'};
  cursor: pointer;
  transition: all 0.2s ease-in-out;
  
  &:hover {
    transform: scale(1.1);
  }
`;

const FormGroup = styled.div`
  margin-bottom: 16px;
`;

const Label = styled.label`
  display: block;
  font-size: 14px;
  font-weight: 500;
  color: ${({ theme }) => theme.text};
  margin-bottom: 8px;
`;

const ErrorText = styled.div`
  color: ${({ theme }) => theme.error};
  font-size: 12px;
  margin-top: 4px;
  margin-left: 4px;
`;

const StyledField = styled(Field)`
  width: 100%;
  padding: 8px 12px;
  background: ${({ theme }) => theme.background};
  border: 1px solid ${({ theme }) => theme.background};
  border-radius: 8px;
  font-size: 14px;
  color: ${({ theme }) => theme.text};
  transition: border-color 0.2s ease-in-out;
  
  &:focus {
    border-color: ${({ theme }) => theme.primary};
  }
`;

const TextArea = styled(StyledField)`
  height: 60px;
  resize: none;
`;

const DraftEditorContainer = styled.div`
  .tox-tinymce {
    border-radius: 0 0 8px 8px;
    border: 1px solid ${({ theme }) => theme.background};
    border-top: none;
  }

  .tox .tox-toolbar__primary {
    background-color: transparent !important;
    border-radius: 8px 8px 0 0;
    border: 1px solid ${({ theme }) => theme.background};
  }

  .tox .tox-edit-area__iframe {
    background-color: ${({ theme }) => theme.surface} !important;
  }

  .tox .tox-tbtn {
    color: ${({ theme }) => theme.text};
    background: transparent !important;
    background-color: transparent !important;
    box-shadow: none !important;
  }

  .tox .tox-tbtn:hover {
    background-color: rgba(63, 81, 181, 0.1) !important;
  }

  .tox .tox-tbtn--enabled, 
  .tox .tox-tbtn--enabled:hover {
    background-color: rgba(63, 81, 181, 0.2) !important;
  }
  
  .tox .tox-toolbar,
  .tox .tox-toolbar__overflow,
  .tox .tox-toolbar__primary {
    background: transparent !important;
  }
  
  .tox .tox-tbtn svg {
    fill: ${({ theme }) => theme.text};
  }
  
  .tox .tox-edit-area {
    border-top: 1px solid ${({ theme }) => theme.background} !important;
  }
  
  .tox.tox-tinymce--toolbar-sticky-on .tox-editor-header {
    background-color: transparent !important;
  }
  
  /* Скрываем бренд TinyMCE и брендовые элементы */
  .tox-statusbar__branding {
    display: none !important;
  }
  
  /* Дополнительно скрываем все элементы, если statusbar отключен не полностью */
  .tox-statusbar__text-container {
    display: none !important;
  }
  
  .tox-statusbar__path-item {
    display: none !important;
  }
  
  .tox-statusbar__wordcount {
    display: none !important;
  }
  
  .tox-statusbar__resize-handle {
    display: none !important;
  }
  
  /* Исправления для панели инструментов */
  .tox .tox-toolbar-overlord {
    background-color: transparent !important;
  }
  
  .tox:not([dir=rtl]) .tox-toolbar__group:not(:last-of-type) {
    border-right: none !important;
  }
  
  /* Стили для выпадающих списков */
  .tox .tox-split-button {
    background-color: transparent !important;
    box-shadow: none !important;
  }
  
  .tox .tox-split-button__chevron {
    background-color: transparent !important;
  }
  
  .tox .tox-tbtn--select {
    background-color: transparent !important;
  }
`;

// Определяем модули и форматы для редактора Quill
// Draft.js toolbars и опции настраиваются в компоненте Editor

const ContentBlock = styled.div`
  width: 100%;
  margin-bottom: 20px;
`;

const ButtonsRow = styled.div`
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
`;

const Button = styled.button`
  height: 40px;
  padding: 0 24px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s ease-in-out;
  
  &:hover {
    opacity: 0.9;
  }
  
  &:active {
    transform: scale(0.98);
  }
`;

const CancelButton = styled(Button)`
  background: ${({ theme }) => theme.background};
  color: ${({ theme }) => theme.textSecondary};
`;

const DeleteButton = styled(Button)`
  background: ${({ theme }) => theme.error};
  color: white;
  margin-left: 16px;
`;

const SaveButton = styled(Button)`
  background: ${({ theme }) => theme.primary};
  color: white;
  margin-left: 16px;
`;

const cardValidationSchema = Yup.object({
  title: Yup.string().required('Заголовок обязателен'),
  description: Yup.string().required('Описание обязательно'),
});

interface CardModalProps {
  card: Card | null;
  workspaceId: string;
  onClose: () => void;
}

const CardModal: React.FC<CardModalProps> = ({ card, workspaceId, onClose }) => {
  const dispatch = useDispatch();
  const { mode } = useSelector((state: RootState) => state.theme);
  const { cardColors } = mode === 'light' ? { cardColors: [] } : { cardColors: [] }; // Will be fixed
  const editorRef = useRef<any>(null);

  // Default colors
  const defaultCardColors = [
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#FF9800', // Orange
  ];

  const colors = cardColors.length > 0 ? cardColors : defaultCardColors;

  const [content, setContent] = useState('');
  const [selectedBackgroundColor, setSelectedBackgroundColor] = useState(colors[0]);
  const [selectedTitleColor, setSelectedTitleColor] = useState('#FFFFFF');
  const [selectedDescriptionColor, setSelectedDescriptionColor] = useState('#FFFFFF');

  // Initialize form values
  useEffect(() => {
    if (card) {
      // Инициализируем содержимое карточки
      if (card.content) {
        setContent(card.content);
      } else {
        setContent('');
      }
      
      setSelectedBackgroundColor(card.backgroundColor || colors[0]);
      setSelectedTitleColor(card.titleColor || '#FFFFFF');
      setSelectedDescriptionColor(card.descriptionColor || '#FFFFFF');
    } else {
      // Инициализируем пустыми значениями для новой карточки
      setContent('');
      setSelectedBackgroundColor(colors[0]);
      setSelectedTitleColor('#FFFFFF');
      setSelectedDescriptionColor('#FFFFFF');
    }
  }, [card, colors]);

  const initialValues = {
    title: card?.title || '',
    description: card?.description || '',
  };

  const handleSubmit = async (values: { title: string; description: string }) => {
    try {
      // Получаем содержимое редактора
      const contentHtml = editorRef.current ? editorRef.current.getContent() : content;
      
      if (card) {
        // Update existing card
        dispatch(updateCardStart());
        
        const updatedCard = await cardService.updateCard(card.id, {
          title: values.title,
          titleColor: selectedTitleColor,
          description: values.description,
          descriptionColor: selectedDescriptionColor,
          content: contentHtml,
          backgroundColor: selectedBackgroundColor,
        });
        
        dispatch(updateCardSuccess(updatedCard));
      } else {
        // Create new card
        dispatch(addCardStart());
        
        const newCard = await cardService.createCard({
          workspaceId,
          title: values.title,
          titleColor: selectedTitleColor,
          description: values.description,
          descriptionColor: selectedDescriptionColor,
          content: contentHtml,
          backgroundColor: selectedBackgroundColor,
          position: { x: 0, y: 0 }, // Default position, will be adjusted by the backend
        });
        
        dispatch(addCardSuccess(newCard));
      }
      
      onClose();
    } catch (error: any) {
      if (card) {
        dispatch(updateCardFailure(error.message || 'Failed to update card'));
      } else {
        dispatch(addCardFailure(error.message || 'Failed to create card'));
      }
    }
  };

  const handleDelete = async () => {
    if (!card) return;
    
    const confirmed = window.confirm('Вы уверены, что хотите удалить эту карточку?');
    if (!confirmed) return;
    
    try {
      await cardService.deleteCard(card.id);
      dispatch(deleteCardSuccess(card.id));
      onClose();
    } catch (error: any) {
      dispatch(deleteCardFailure(error.message || 'Failed to delete card'));
    }
  };

  return (
    <ModalOverlay>
      <ModalContainer>
        <ModalTitle>
          {card ? 'Редактирование карточки' : 'Создание карточки'}
        </ModalTitle>
        
        <Formik
          initialValues={initialValues}
          validationSchema={cardValidationSchema}
          onSubmit={handleSubmit}
        >
          {({ values, handleChange, handleBlur, handleSubmit: formikSubmit }) => (
            <Form>
              <ModalContent>
                <LeftColumn>
                  <CardPreview backgroundColor={selectedBackgroundColor}>
                    <PreviewTitle color={selectedTitleColor}>
                      {values.title || 'Заголовок карточки'}
                    </PreviewTitle>
                    <PreviewDescription color={selectedDescriptionColor}>
                      {values.description || 'Описание карточки будет отображаться здесь. Вы можете добавить небольшое описание для быстрого понимания содержимого карточки.'}
                    </PreviewDescription>
                  </CardPreview>
                  
                  <ColorPalette>
                    {colors.map((color) => (
                      <ColorButton
                        key={color}
                        color={color}
                        isSelected={selectedBackgroundColor === color}
                        onClick={() => setSelectedBackgroundColor(color)}
                        type="button"
                      />
                    ))}
                  </ColorPalette>
                </LeftColumn>
                
                <RightColumn>
                  <FormGroup>
                    <Label>Заголовок</Label>
                    <StyledField
                      type="text"
                      name="title"
                      placeholder="Введите заголовок карточки"
                      onChange={(e: React.ChangeEvent<HTMLInputElement>) => {
                        handleChange(e);
                      }}
                      onBlur={handleBlur}
                    />
                    <ErrorMessage name="title" component={ErrorText} />
                    
                    <ColorPalette>
                      {['#FFFFFF', '#F0F0F0', '#FFEB3B', '#4CAF50', '#2196F3'].map((color) => (
                        <ColorButton
                          key={color}
                          color={color}
                          isSelected={selectedTitleColor === color}
                          onClick={() => setSelectedTitleColor(color)}
                          type="button"
                        />
                      ))}
                    </ColorPalette>
                  </FormGroup>
                  
                  <FormGroup>
                    <Label>Описание</Label>
                    <TextArea
                      as="textarea"
                      name="description"
                      placeholder="Введите краткое описание карточки"
                      onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => {
                        handleChange(e); // Вызываем стандартный обработчик Formik
                      }}
                      onBlur={handleBlur}
                    />
                    <ErrorMessage name="description" component={ErrorText} />
                    
                    <ColorPalette>
                      {['#FFFFFF', '#F0F0F0', '#FFEB3B', '#4CAF50', '#2196F3'].map((color) => (
                        <ColorButton
                          key={color}
                          color={color}
                          isSelected={selectedDescriptionColor === color}
                          onClick={() => setSelectedDescriptionColor(color)}
                          type="button"
                        />
                      ))}
                    </ColorPalette>
                  </FormGroup>
                </RightColumn>
              </ModalContent>
              
              <ContentBlock>
                <FormGroup>
                  <Label>Содержимое</Label>
                  <DraftEditorContainer>
                    <Editor
                      apiKey="lctkeed8fi8408gnrhqwj091g8xxu1ly1zx9f9gxm9kqghxg"
                      onInit={(evt, editor) => editorRef.current = editor}
                      initialValue={content}
                      init={{
                        height: 250,
                        menubar: false,
                        statusbar: false,
                        plugins: [
                          'advlist', 'autolink', 'lists', 'link', 'image', 'charmap', 'preview',
                          'anchor', 'searchreplace', 'visualblocks', 'code', 'fullscreen',
                          'insertdatetime', 'media', 'table', 'help', 'wordcount'
                        ],
                        toolbar: 'undo redo | formatselect | ' +
                          'bold italic forecolor backcolor | alignleft aligncenter ' +
                          'alignright alignjustify | bullist numlist outdent indent | ' +
                          'removeformat',
                        content_style: 'body { font-family:Roboto,Arial,sans-serif; font-size:14px; background-color: ' + 
                          (mode === 'dark' ? '#1E1E1E' : '#FFFFFF') + '; color: ' + 
                          (mode === 'dark' ? '#FFFFFF' : '#212121') + ' }',
                        skin: mode === 'dark' ? 'oxide-dark' : 'oxide',
                        content_css: mode === 'dark' ? 'dark' : 'default',
                        toolbar_sticky: false,
                        toolbar_mode: 'wrap',
                        // Удалено поле base_url, которое может вызывать проблемы
                        color_map: [
                          "#FFFFFF", "White",
                          "#F0F0F0", "Light Grey",
                          "#212121", "Black",
                          "#3F51B5", "Indigo (Primary)",
                          "#FF4081", "Pink (Accent)",
                          "#F44336", "Red",
                          "#E91E63", "Pink",
                          "#9C27B0", "Purple",
                          "#673AB7", "Deep Purple",
                          "#2196F3", "Blue",
                          "#00BCD4", "Cyan",
                          "#009688", "Teal",
                          "#4CAF50", "Green",
                          "#FF9800", "Orange"
                        ]
                        // Удалили настройку setup, которая может вызывать проблемы
                      }}
                    />
                  </DraftEditorContainer>
                </FormGroup>
              </ContentBlock>
              
              <ButtonsRow>
                <CancelButton type="button" onClick={(e) => {
                  e.preventDefault();
                  onClose();
                }}>
                  Отменить
                </CancelButton>
                
                {card && (
                  <DeleteButton type="button" onClick={handleDelete}>
                    Удалить
                  </DeleteButton>
                )}
                
                <SaveButton type="submit">
                  Сохранить
                </SaveButton>
              </ButtonsRow>
            </Form>
          )}
        </Formik>
      </ModalContainer>
    </ModalOverlay>
  );
};

export default CardModal;
