declare module 'react-beautiful-dnd' {
  export interface DropResult {
    draggableId: string;
    type: string;
    source: {
      droppableId: string;
      index: number;
    };
    destination?: {
      droppableId: string;
      index: number;
    };
    reason: 'DROP' | 'CANCEL';
  }

  export interface DraggableStateSnapshot {
    isDragging: boolean;
    draggingOver?: string;
  }

  export interface DroppableStateSnapshot {
    isDraggingOver: boolean;
    draggingOverWith?: string;
  }

  export interface DraggableProvided {
    draggableProps: any;
    dragHandleProps: any;
    innerRef: (element?: HTMLElement | null) => void;
  }

  export interface DroppableProvided {
    innerRef: (element?: HTMLElement | null) => void;
    droppableProps: any;
    placeholder?: React.ReactNode;
  }

  export interface DroppableProps {
    droppableId: string;
    type?: string;
    direction?: 'horizontal' | 'vertical';
    isDropDisabled?: boolean;
    isCombineEnabled?: boolean;
    ignoreContainerClipping?: boolean;
    children: (provided: DroppableProvided, snapshot: DroppableStateSnapshot) => React.ReactNode;
  }

  export interface DraggableProps {
    draggableId: string;
    index: number;
    isDragDisabled?: boolean;
    disableInteractiveElementBlocking?: boolean;
    children: (provided: DraggableProvided, snapshot: DraggableStateSnapshot) => React.ReactNode;
  }

  export interface DragDropContextProps {
    onDragStart?: (start: any) => void;
    onDragUpdate?: (update: any) => void;
    onDragEnd: (result: DropResult) => void;
    children: React.ReactNode;
  }

  export const DragDropContext: React.FC<DragDropContextProps>;
  export const Droppable: React.FC<DroppableProps>;
  export const Draggable: React.FC<DraggableProps>;
}
