#!/bin/bash
# Day 2: GitHub Activity Script
# This script helps you add your Day 2 work to GitHub

set -e  # Exit on any error

echo "=== AWS Interview Prep - Day 2 GitHub Activity ==="
echo "This script will help you add your Day 2 S3 work to GitHub"
echo ""

# Check if we're in the right directory
if [ ! -f "../../README.md" ]; then
    echo "Error: Please run this script from the day02-s3-storage directory"
    exit 1
fi

# Configure git if not already done
if [ ! -f ~/.gitconfig ]; then
    echo "Setting up git configuration..."
    read -p "Enter your GitHub username: " GIT_USER
    read -p "Enter your GitHub email: " GIT_EMAIL
    git config --global user.name "$GIT_USER"
    git config --global user.email "$GIT_EMAIL"
fi

# Initialize git repo if needed
if [ ! -d .git ]; then
    echo "Initializing git repository..."
    git init
    git remote add origin https://github.com/abhinavpadige4/aws-cloud-engineer-interview-prep.git
    git branch -M main
fi

# Pull latest changes
echo "Pulling latest changes from remote..."
git pull origin main || echo "Could not pull (may be first push)"

# Add Day 2 files
echo "Adding Day 2 files to git..."
git add day02-s3-storage/notes.md
git add day02-s3-storage/practice-questions.md
git add day02-s3-storage/hands-on-exercise.md

# Optional: Add any personal notes or scripts you created
if [ -f "personal-notes.md" ]; then
    git add personal-notes.md
    echo "Added personal-notes.md"
fi

if [ -f "s3-setup-script.sh" ]; then
    git add s3-setup-script.sh
    echo "Added s3-setup-script.sh"
fi

if [ -f "lifecycle-policy.json" ]; then
    git add lifecycle-policy.json
    echo "Added lifecycle-policy.json"
fi

if [ -f "bucket-policy.json" ]; then
    git add bucket-policy.json
    echo "Added bucket-policy.json"
fi

# Commit changes
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
COMMIT_MESSAGE="Day 2: S3 Storage - Completed study, practice questions, and hands-on exercise [$TIMESTAMP]"

echo "Committing changes..."
git commit -m "$COMMIT_MESSAGE"

# Push to GitHub
echo "Pushing to GitHub..."
git push origin main

echo ""
echo "=== Day 2 GitHub Activity Complete ==="
echo "Your Day 2 work has been pushed to:"
echo "https://github.com/abhinavpadige4/aws-cloud-engineer-interview-prep"
echo ""
echo "Next Steps:"
echo "1. Verify your files appear on GitHub"
echo "2. Proceed to Day 3: VPC Networking"
echo "3. Repeat this process for each day"