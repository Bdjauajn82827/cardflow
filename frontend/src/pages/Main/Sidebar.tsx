import React, { useState } from 'react';
import { styled } from 'styled-components';
import { Workspace } from '../../models';
import { workspaceService } from '../../services/workspaceService';

// Icons
const AddIcon = () => (
  <span className="mdi mdi-plus" style={{ fontSize: '24px' }}></span>
);

const HomeIcon = () => (
  <span className="mdi mdi-home" style={{ fontSize: '24px' }}></span>
);

const AddWorkspaceIcon = () => (
  <span className="mdi mdi-plus-box-outline" style={{ fontSize: '18px' }}></span>
);

const ProfileIcon = () => (
  <span className="mdi mdi-account-cog" style={{ fontSize: '24px' }}></span>
);

const SidebarContainer = styled.div`
  width: 80px;
  height: 100%;
  background: ${({ theme }) => theme.surface};
  box-shadow: 2px 0 10px rgba(0, 0, 0, 0.05);
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 16px 10px;
  z-index: 10;
`;

const AddCardButton = styled.button`
  width: 60px;
  height: 60px;
  background: ${({ theme }) => theme.primary};
  color: white;
  border-radius: 12px;
  margin-top: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease-in-out;
  
  &:hover {
    transform: scale(1.05);
    opacity: 0.95;
  }
  
  &:active {
    transform: scale(0.98);
  }
`;

const Divider = styled.div`
  width: 60px;
  height: 2px;
  background: ${({ theme }) => theme.background};
  margin: 16px 0;
  border-style: dashed;
  border-width: 0;
  border-top-width: 2px;
  border-color: ${({ theme }) => theme.textSecondary};
  opacity: 0.3;
`;

interface WorkspaceButtonProps {
  active: boolean;
}

const WorkspaceButton = styled.button<WorkspaceButtonProps>`
  width: 60px;
  height: 60px;
  background: ${({ theme, active }) => 
    active 
      ? theme.surface
      : theme.background
  };
  color: ${({ theme, active }) => 
    active 
      ? theme.primary 
      : theme.textSecondary
  };
  border-radius: 12px;
  margin-top: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease-in-out;
  position: relative;
  
  &::before {
    content: '';
    position: absolute;
    left: -10px;
    top: 0;
    bottom: 0;
    width: 3px;
    background: ${({ theme, active }) => active ? theme.primary : 'transparent'};
    border-radius: 0 3px 3px 0;
  }
  
  &:hover {
    background: ${({ theme, active }) => 
      active 
        ? theme.surface
        : theme.background
    };
    opacity: ${({ active }) => active ? 1 : 0.8};
  }
`;

const AddWorkspaceButton = styled.button`
  width: 60px;
  height: 30px;
  background: ${({ theme }) => theme.background};
  color: ${({ theme }) => theme.textSecondary};
  border-radius: 8px;
  margin-top: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease-in-out;
  
  &:hover {
    background: ${({ theme }) => theme.background};
    opacity: 0.8;
  }
`;

const ProfileButton = styled.button`
  width: 60px;
  height: 60px;
  background: ${({ theme }) => theme.background};
  color: ${({ theme }) => theme.primary};
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease-in-out;
  margin-top: auto;
  
  &:hover {
    background: ${({ theme }) => theme.background};
    opacity: 0.8;
  }
`;

const WorkspaceText = styled.span`
  font-size: 18px;
  font-weight: 500;
`;

interface SidebarProps {
  workspaces: Workspace[];
  activeWorkspaceId: string | null;
  onWorkspaceChange: (id: string) => void;
  onAddCardClick: () => void;
  onProfileClick: () => void;
}

const Sidebar: React.FC<SidebarProps> = ({
  workspaces,
  activeWorkspaceId,
  onWorkspaceChange,
  onAddCardClick,
  onProfileClick,
}) => {
  const [isCreatingWorkspace, setIsCreatingWorkspace] = useState(false);

  const handleAddWorkspace = async () => {
    if (workspaces.length >= 7) {
      alert('Максимальное количество рабочих пространств: 7');
      return;
    }

    try {
      setIsCreatingWorkspace(true);
      const name = prompt('Введите название рабочего пространства:');
      
      if (!name) {
        setIsCreatingWorkspace(false);
        return;
      }
      
      await workspaceService.createWorkspace({
        name,
        order: workspaces.length
      });
      
      // Refresh will happen via Redux
    } catch (error) {
      console.error('Failed to create workspace:', error);
      alert('Не удалось создать рабочее пространство');
    } finally {
      setIsCreatingWorkspace(false);
    }
  };

  return (
    <SidebarContainer>
      <AddCardButton onClick={onAddCardClick}>
        <AddIcon />
      </AddCardButton>
      
      <Divider />
      
      {workspaces.map((workspace) => (
        <WorkspaceButton
          key={workspace.id}
          active={workspace.id === activeWorkspaceId}
          onClick={() => onWorkspaceChange(workspace.id)}
        >
          {workspace.order === 0 ? (
            <HomeIcon />
          ) : (
            <WorkspaceText>{workspace.name.charAt(0).toUpperCase()}</WorkspaceText>
          )}
        </WorkspaceButton>
      ))}
      
      {workspaces.length < 7 && (
        <AddWorkspaceButton 
          onClick={handleAddWorkspace}
          disabled={isCreatingWorkspace}
        >
          <AddWorkspaceIcon />
        </AddWorkspaceButton>
      )}
      
      <ProfileButton onClick={onProfileClick}>
        <ProfileIcon />
      </ProfileButton>
    </SidebarContainer>
  );
};

export default Sidebar;
