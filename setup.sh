#!/bin/bash

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}====================================${NC}"
echo -e "${YELLOW}        CardFlow Setup Script       ${NC}"
echo -e "${YELLOW}====================================${NC}"

# Function to check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

# Check if Node.js is installed
if command_exists node; then
  NODE_VERSION=$(node -v)
  echo -e "${GREEN}✓${NC} Node.js is installed (${NODE_VERSION})"
else
  echo -e "${RED}✗${NC} Node.js is not installed. Please install Node.js v14 or higher."
  exit 1
fi

# Check if npm is installed
if command_exists npm; then
  NPM_VERSION=$(npm -v)
  echo -e "${GREEN}✓${NC} npm is installed (${NPM_VERSION})"
else
  echo -e "${RED}✗${NC} npm is not installed. Please install npm."
  exit 1
fi

# Check if MongoDB is installed (optional)
if command_exists mongod; then
  MONGO_VERSION=$(mongod --version | grep "db version" | sed 's/db version v//')
  echo -e "${GREEN}✓${NC} MongoDB is installed (${MONGO_VERSION})"
else
  echo -e "${YELLOW}⚠${NC} MongoDB is not installed locally. You can use a cloud MongoDB instance or Docker."
fi

# Ask what to install
echo -e "\n${YELLOW}What would you like to set up?${NC}"
echo "1) Install backend dependencies"
echo "2) Install frontend dependencies"
echo "3) Install all dependencies (backend + frontend)"
echo "4) Start development servers"
echo "5) Build for production"
echo "6) Start Docker development environment"
echo "7) Exit"

read -p "Enter your choice (1-7): " choice

case $choice in
  1)
    echo -e "\n${YELLOW}Installing backend dependencies...${NC}"
    cd backend && npm install
    echo -e "${GREEN}✓${NC} Backend dependencies installed successfully!"
    ;;
  2)
    echo -e "\n${YELLOW}Installing frontend dependencies...${NC}"
    cd frontend && npm install
    echo -e "${GREEN}✓${NC} Frontend dependencies installed successfully!"
    ;;
  3)
    echo -e "\n${YELLOW}Installing backend dependencies...${NC}"
    cd backend && npm install
    echo -e "${GREEN}✓${NC} Backend dependencies installed successfully!"
    
    echo -e "\n${YELLOW}Installing frontend dependencies...${NC}"
    cd ../frontend && npm install
    echo -e "${GREEN}✓${NC} Frontend dependencies installed successfully!"
    ;;
  4)
    echo -e "\n${YELLOW}Starting development servers...${NC}"
    
    # Check if MongoDB is running
    if command_exists mongod; then
      if pgrep -x "mongod" > /dev/null; then
        echo -e "${GREEN}✓${NC} MongoDB is already running."
      else
        echo -e "${YELLOW}⚠${NC} MongoDB is not running. Starting MongoDB..."
        mongod --fork --logpath /tmp/mongodb.log
        echo -e "${GREEN}✓${NC} MongoDB started successfully!"
      fi
    else
      echo -e "${YELLOW}⚠${NC} MongoDB is not installed locally. Make sure you have a MongoDB instance available."
    fi
    
    # Start backend server in the background
    echo -e "${YELLOW}Starting backend server...${NC}"
    cd backend && npm run dev &
    BACKEND_PID=$!
    echo -e "${GREEN}✓${NC} Backend server started on http://localhost:5000"
    
    # Start frontend development server
    echo -e "${YELLOW}Starting frontend development server...${NC}"
    cd ../frontend && npm start
    
    # Cleanup when frontend server is stopped
    kill $BACKEND_PID
    ;;
  5)
    echo -e "\n${YELLOW}Building for production...${NC}"
    
    echo -e "${YELLOW}Building frontend...${NC}"
    cd frontend && npm run build
    echo -e "${GREEN}✓${NC} Frontend built successfully!"
    
    echo -e "\n${YELLOW}Production build completed!${NC}"
    echo -e "You can now deploy the application using one of the methods described in the README.md file."
    ;;
  6)
    echo -e "\n${YELLOW}Starting Docker development environment...${NC}"
    if command_exists docker && command_exists docker-compose; then
      docker-compose up
    else
      echo -e "${RED}✗${NC} Docker and/or Docker Compose are not installed. Please install them first."
    fi
    ;;
  7)
    echo -e "\n${YELLOW}Exiting setup script.${NC}"
    exit 0
    ;;
  *)
    echo -e "\n${RED}Invalid choice. Exiting.${NC}"
    exit 1
    ;;
esac

echo -e "\n${GREEN}Setup completed successfully!${NC}"
