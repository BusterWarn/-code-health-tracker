#!/bin/bash

# Code Health Tracker Setup Script

set -e

echo "🏥 Code Health Tracker - Setup"
echo "================================"
echo ""

# Check if Elixir is installed
if ! command -v elixir &> /dev/null; then
    echo "❌ Elixir is not installed."
    echo ""
    echo "Please install Elixir first:"
    echo "  macOS:        brew install elixir"
    echo "  Ubuntu/Debian: sudo apt-get install elixir"
    echo "  Other:        https://elixir-lang.org/install.html"
    exit 1
fi

echo "✅ Elixir found: $(elixir --version | head -1)"
echo ""

# Check if OpenAI API key is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠️  OPENAI_API_KEY is not set."
    echo ""
    echo "Please set your OpenAI API key:"
    echo "  export OPENAI_API_KEY='sk-...'"
    echo ""
    echo "Get your API key from: https://platform.openai.com/api-keys"
    echo ""
    read -p "Do you want to continue without it? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ OPENAI_API_KEY is set"
    echo ""
fi

# Install dependencies
echo "📦 Installing dependencies..."
mix deps.get

echo ""
echo "🔨 Building executable..."
mix escript.build

echo ""
echo "✅ Setup complete!"
echo ""
echo "You can now run:"
echo "  ./code-health help"
echo ""
echo "Or install globally:"
echo "  sudo cp code-health /usr/local/bin/"
echo ""
echo "Happy code health tracking! ✨"
