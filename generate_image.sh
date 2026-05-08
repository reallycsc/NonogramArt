#!/bin/bash

set -e

if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY is not set"
    exit 1
fi

PROMPT="${1:-A beautiful sunset over a mountain lake}"
SIZE="${2:-1024x1024}"
QUALITY="${3:-standard}"
N="${4:-1}"

RESPONSE=$(curl -s -X POST https://api.openai.com/v1/images/generations \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-image-2",
    "prompt": "'"$PROMPT"'",
    "size": "'"$SIZE"'",
    "quality": "'"$QUALITY"'",
    "n": '"$N"'
  }')

echo "Response:"
echo "$RESPONSE" | jq .

IMAGE_URL=$(echo "$RESPONSE" | jq -r '.data[0].url')

if [ "$IMAGE_URL" != "null" ]; then
    echo ""
    echo "Generated image URL: $IMAGE_URL"
    
    read -p "Download image? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p output
        curl -s -o "output/image_$(date +%Y%m%d_%H%M%S).png" "$IMAGE_URL"
        echo "Image saved to output directory"
    fi
fi