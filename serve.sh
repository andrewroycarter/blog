#!/bin/bash

# Build the site
echo "Building site..."
swift run blog build

# Check if the build was successful
if [ $? -eq 0 ]; then
    echo "Site built successfully!"
    echo "Starting server at http://localhost:8000"
    echo "Press Ctrl+C to stop the server"
    
    # Change to the public directory and start Python's HTTP server
    cd public && python3 -m http.server 8000
else
    echo "Failed to build site"
    exit 1
fi 