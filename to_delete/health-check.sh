#!/bin/bash

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}====================================${NC}"
echo -e "${YELLOW}    CardFlow Health Check Script    ${NC}"
echo -e "${YELLOW}====================================${NC}"

# Check if MongoDB is running
echo -e "\n${YELLOW}Checking MongoDB...${NC}"
if pgrep -x "mongod" > /dev/null; then
    echo -e "${GREEN}✓${NC} MongoDB is running."
else
    echo -e "${RED}✗${NC} MongoDB is not running."
    echo -e "  Try starting it with: ${YELLOW}mongod${NC}"
fi

# Check if backend is running
echo -e "\n${YELLOW}Checking backend service...${NC}"
if curl -s http://localhost:5000/api/health > /dev/null; then
    echo -e "${GREEN}✓${NC} Backend is running on port 5000."
else
    echo -e "${RED}✗${NC} Backend is not running or not accessible."
    echo -e "  Try starting it with: ${YELLOW}cd backend && npm run dev${NC}"
fi

# Check if frontend is running
echo -e "\n${YELLOW}Checking frontend service...${NC}"
if curl -s http://localhost:3000 > /dev/null; then
    echo -e "${GREEN}✓${NC} Frontend is running on port 3000."
else
    echo -e "${RED}✗${NC} Frontend is not running or not accessible."
    echo -e "  Try starting it with: ${YELLOW}cd frontend && npm start${NC}"
fi

# Check Docker (if used)
echo -e "\n${YELLOW}Checking Docker containers (if used)...${NC}"
if command -v docker > /dev/null; then
    # Check if CardFlow containers are running
    MONGO_CONTAINER=$(docker ps | grep cardflow-mongodb)
    BACKEND_CONTAINER=$(docker ps | grep cardflow-backend)
    FRONTEND_CONTAINER=$(docker ps | grep cardflow-frontend)
    
    if [ ! -z "$MONGO_CONTAINER" ]; then
        echo -e "${GREEN}✓${NC} MongoDB container is running."
    else
        echo -e "${YELLOW}⚠${NC} MongoDB container is not running."
    fi
    
    if [ ! -z "$BACKEND_CONTAINER" ]; then
        echo -e "${GREEN}✓${NC} Backend container is running."
    else
        echo -e "${YELLOW}⚠${NC} Backend container is not running."
    fi
    
    if [ ! -z "$FRONTEND_CONTAINER" ]; then
        echo -e "${GREEN}✓${NC} Frontend container is running."
    else
        echo -e "${YELLOW}⚠${NC} Frontend container is not running."
    fi
    
    if [ -z "$MONGO_CONTAINER" ] && [ -z "$BACKEND_CONTAINER" ] && [ -z "$FRONTEND_CONTAINER" ]; then
        echo -e "${YELLOW}⚠${NC} No CardFlow Docker containers are running."
        echo -e "  Try starting them with: ${YELLOW}docker-compose up -d${NC}"
    fi
else
    echo -e "${YELLOW}⚠${NC} Docker is not installed or not in PATH."
fi

echo -e "\n${YELLOW}Health check completed.${NC}"
