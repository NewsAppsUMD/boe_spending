#!/bin/bash
# BOE Spending Database Build and Deployment Script
# Builds SQLite database from cleaned CSV and deploys to Heroku

set -e  # Exit on error

echo "Building BOE Spending Database..."

# Clean up old database
rm -f databases/boe_spending.db

# Install dependencies
echo "Installing Python dependencies..."
pip install -q sqlite-utils datasette

# Create database from CSV
echo "Creating SQLite database from processed data..."
sqlite-utils insert databases/boe_spending.db vendors data/processed/boe_spending_cleaned.csv --csv

# Transform data types
echo "Setting data types..."
sqlite-utils transform databases/boe_spending.db vendors --type amount float

# Enable full-text search
echo "Enabling full-text search..."
sqlite-utils enable-fts databases/boe_spending.db vendors payee_name purpose_of_payment_baltimore_county_only

# Optimize database
echo "Optimizing database..."
sqlite-utils vacuum databases/boe_spending.db

echo "Database built successfully: databases/boe_spending.db"

# Deploy to Heroku
echo "Deploying to Heroku..."
datasette publish heroku databases/boe_spending.db -n md-boe-spending --template-dir templates/

echo "Deployment complete!"
