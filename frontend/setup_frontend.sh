#!/bin/bash
#
# Setup SvelteKit Frontend
# Installs dependencies and prepares for development
#

set -e

echo "========================================================================"
echo "Setting up EV Charging Analytics Frontend (SvelteKit)"
echo "========================================================================"
echo ""

# Check if in correct directory
if [ ! -f "package.json" ]; then
    echo "ERROR: package.json not found"
    echo "Please run from frontend/ directory"
    exit 1
fi

echo "✓ In correct directory"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js not found"
    echo "Please install Node.js 18+ from https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node --version)
echo "✓ Node.js found: $NODE_VERSION"
echo ""

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "ERROR: npm not found"
    exit 1
fi

NPM_VERSION=$(npm --version)
echo "✓ npm found: v$NPM_VERSION"
echo ""

# Install dependencies
echo "Installing npm dependencies..."
echo "This may take a few minutes..."
echo ""

npm install

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Dependencies installed successfully"
else
    echo ""
    echo "✗ Dependency installation failed"
    exit 1
fi

echo ""
echo "========================================================================"
echo "Setup Complete!"
echo "========================================================================"
echo ""
echo "Frontend is ready to run"
echo ""
echo "To start the development server:"
echo "  npm run dev"
echo ""
echo "The dashboard will be available at:"
echo "  http://localhost:5173"
echo ""
echo "Make sure the FastAPI backend is running on port 8000:"
echo "  cd ../backend && ./start_backend.sh"
echo ""
