import React from 'react';
import { styled } from 'styled-components';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from '../../store';
import { logout } from '../../store/slices/authSlice';
import { setTheme } from '../../store/slices/themeSlice';
import { authService } from '../../services/api';

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
  width: 600px;
  height: 400px;
  background: ${({ theme }) => theme.surface};
  border-radius: 16px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
  padding: 24px;
  display: flex;
  flex-direction: column;
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
  flex: 1;
  overflow: hidden;
`;

const LeftColumn = styled.div`
  width: 50%;
  padding-right: 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  position: relative;
  
  &::after {
    content: '';
    position: absolute;
    top: 0;
    right: 0;
    width: 1px;
    height: 100%;
    background: ${({ theme }) => theme.background};
  }
`;

const RightColumn = styled.div`
  width: 50%;
  padding-left: 16px;
  display: flex;
  flex-direction: column;
`;

const UserInfo = styled.div`
  text-align: center;
`;

const UserName = styled.h3`
  font-size: 18px;
  font-weight: 500;
  color: ${({ theme }) => theme.text};
  margin-bottom: 4px;
`;

const UserEmail = styled.p`
  font-size: 14px;
  color: ${({ theme }) => theme.textSecondary};
  margin-bottom: 4px;
`;

const UserDate = styled.p`
  font-size: 14px;
  color: ${({ theme }) => theme.textSecondary};
  margin-bottom: 24px;
`;

const LogoutButton = styled.button`
  width: 120px;
  height: 40px;
  background: ${({ theme }) => theme.error};
  color: white;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  
  &:hover {
    opacity: 0.9;
  }
`;

const SettingsGroup = styled.div`
  margin-bottom: 24px;
`;

const SettingsLabel = styled.h4`
  font-size: 16px;
  font-weight: 500;
  color: ${({ theme }) => theme.text};
  margin-bottom: 12px;
`;

interface ThemeSwitchProps {
  isActive: boolean;
}

const ThemeSwitch = styled.div<ThemeSwitchProps>`
  width: 60px;
  height: 30px;
  background: ${({ theme, isActive }) => 
    isActive ? theme.primary : theme.background
  };
  border-radius: 15px;
  position: relative;
  cursor: pointer;
  display: flex;
  align-items: center;
  padding: 0 5px;
  justify-content: space-between;
`;

const ThemeIcon = styled.span`
  font-size: 16px;
  color: ${({ theme }) => theme.surface};
  z-index: 1;
`;

const SwitchKnob = styled.div<ThemeSwitchProps>`
  width: 24px;
  height: 24px;
  background: white;
  border-radius: 50%;
  position: absolute;
  top: 3px;
  left: ${({ isActive }) => isActive ? '33px' : '3px'};
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
`;

const ButtonsRow = styled.div`
  display: flex;
  justify-content: center;
  margin-top: auto;
`;

const CloseButton = styled.button`
  width: 120px;
  height: 40px;
  background: ${({ theme }) => theme.primary};
  color: white;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  
  &:hover {
    opacity: 0.9;
  }
`;

interface ProfileModalProps {
  onClose: () => void;
}

const ProfileModal: React.FC<ProfileModalProps> = ({ onClose }) => {
  const dispatch = useDispatch();
  const { user } = useSelector((state: RootState) => state.auth);
  const { mode: themeMode } = useSelector((state: RootState) => state.theme);
  
  const handleLogout = () => {
    const confirmed = window.confirm('Вы уверены, что хотите выйти?');
    if (!confirmed) return;
    
    authService.logout();
    dispatch(logout());
  };
  
  const handleThemeToggle = () => {
    const newTheme = themeMode === 'light' ? 'dark' : 'light';
    dispatch(setTheme(newTheme));
  };
  
  const formatDate = (dateString?: string) => {
    if (!dateString) return 'Дата регистрации неизвестна';
    const date = new Date(dateString);
    return `Пользователь с ${date.toLocaleDateString('ru-RU')}`;
  };

  return (
    <ModalOverlay>
      <ModalContainer>
        <ModalTitle>Профиль и настройки</ModalTitle>
        
        <ModalContent>
          <LeftColumn>
            <UserInfo>
              <UserName>{user?.name || 'Пользователь'}</UserName>
              <UserEmail>{user?.email || 'email@example.com'}</UserEmail>
              <UserDate>{formatDate(user?.registrationDate)}</UserDate>
            </UserInfo>
            
            <LogoutButton onClick={handleLogout}>
              Выйти
            </LogoutButton>
          </LeftColumn>
          
          <RightColumn>
            <SettingsGroup>
              <SettingsLabel>Тема интерфейса</SettingsLabel>
              <ThemeSwitch 
                isActive={themeMode === 'dark'} 
                onClick={handleThemeToggle}
              >
                <ThemeIcon className="mdi mdi-white-balance-sunny" />
                <ThemeIcon className="mdi mdi-moon-waning-crescent" />
                <SwitchKnob isActive={themeMode === 'dark'} />
              </ThemeSwitch>
            </SettingsGroup>
            
            <ButtonsRow>
              <CloseButton onClick={onClose}>
                Закрыть
              </CloseButton>
            </ButtonsRow>
          </RightColumn>
        </ModalContent>
      </ModalContainer>
    </ModalOverlay>
  );
};

export default ProfileModal;
