#!/bin/bash
echo "🌐 Starting Gramps Web Frontend..."

cd gramps-web

# Set API URL for development
export API_URL=http://localhost:5000

# Start the development server (using the correct script name)
npm start