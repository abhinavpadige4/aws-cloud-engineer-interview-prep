#!/bin/bash
# Day 3: GitHub Activity Script
# This script helps you add your Day 3 work to GitHub

set -e  # Exit on any error

echo "=== AWS Interview Prep - Day 3 GitHub Activity ==="
echo "This script will help you add your Day 3 VPC work to GitHub"
echo ""

# Check if we're in the right directory
if [ ! -f "../../../README.md" ]; then
    echo "Error: Please run this script from the day03-vpc-networking directory"
    exit 1
fi

# Configure git if not already done
if [ ! -f ~/.gitconfig ]; then
    echo("Setting up git configuration...")
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

# Add Day 3 files
echo "Adding Day 3 files to git..."
git add day03-vpc-networking/notes.md
git add day03-vpc-networking/practice-questions.md
git add day03-vpc-networking/hands-on-exercise.md

# Optional: Add any personal notes or scripts you created
if [ -f "personal-notes.md" ]; then
    git add personal-notes.md
    echo "Added personal-notes.md"
fi

if [ -f "vpc-setup-script.sh" ]; then
    git add vpc-setup-script.sh
    echo "Added vpc-setup-script.sh"
fi

if [ -f "network-diagram.txt" ]; then
    git add network-diagram.txt
    echo "Added network-diagram.txt"
fi

# Commit changes
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
COMMIT_MESSAGE="Day 3: VPC Networking - Completed study, practice questions, and hands-on exercise [$TIMESTAMP]"

echo "Committing changes..."
git commit -m "$COMMIT_MESSAGE"

# Push to GitHub
echo "Pushing to GitHub..."
git push origin main

echo ""
echo "=== Day 3 GitHub Activity Complete ==="
echo "Your Day 3 work has been pushed to:"
echo "https://github.com/abhinavpadige4/aws-cloud-engineer-interview-prep"
echo ""
echo "Next Steps:"
echo "1. Verify your files appear on GitHub"
echo "2. Proceed to Day 4: IAM Security"
echo "3. Repeat this process for each day"