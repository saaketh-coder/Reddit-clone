#!/bin/bash
# Helper script to cleanly start the Reddit Clone server

PORT=${1:-8080}

echo "🧹 Cleaning up any existing server processes..."
pkill -9 -f "gleam run -m server" 2>/dev/null || true
pkill -9 beam.smp 2>/dev/null || true
sleep 1

echo "🚀 Starting server on port $PORT..."
echo ""
echo "⚠️  The server will run in the FOREGROUND"
echo "   Press Ctrl+C to stop it"
echo ""
echo "   To test in another terminal, run:"
echo "   curl http://localhost:$PORT/health"
echo ""
echo "────────────────────────────────────────"
echo ""

gleam run -m server $PORT
