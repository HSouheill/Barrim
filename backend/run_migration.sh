#!/bin/bash

# Run the user status migration
echo "Running user status migration..."
mongosh --file migrate_user_status.js

echo "Migration completed!" 