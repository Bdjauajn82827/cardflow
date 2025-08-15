declare module 'react-quill' {
  import React from 'react';
  
  export interface ReactQuillProps {
    theme?: string;
    value?: string;
    onChange?: (content: string) => void;
    modules?: any;
    formats?: string[];
    placeholder?: string;
    readOnly?: boolean;
    defaultValue?: string;
    className?: string;
    style?: React.CSSProperties;
  }
  
  export default class ReactQuill extends React.Component<ReactQuillProps> {}
}
