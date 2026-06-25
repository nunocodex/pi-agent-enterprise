#!/bin/bash
# setup.sh – Installa le dipendenze Python per le skill RAG

VENV_PATH="$HOME/.pi/venv"
REQUIREMENTS_PATH="$HOME/.pi/requirements.txt"

if [ ! -d "$VENV_PATH" ]; then
    echo "❌ Virtual environment not found at $VENV_PATH"
    echo "Create it first: python3 -m venv $VENV_PATH"
    exit 1
fi

source "$VENV_PATH/bin/activate"
pip install -r "$REQUIREMENTS_PATH"
deactivate

echo "✅ RAG client dependencies installed."