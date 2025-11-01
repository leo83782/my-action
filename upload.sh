#!/bin/bash
set -e

echo "🚀 ========================================"
echo "🚀 My Action Upload Script Starting"
echo "🚀 ========================================"
echo "📅 Timestamp: $(date)"
echo ""

# Check required inputs
echo "🔍 Checking required environment variables..."
echo "   API_KEY: ${API_KEY:0:10}... (${#API_KEY} chars)"
echo "   FILE_PATH: $FILE_PATH"
echo "   X_APP_PACKAGE: $X_APP_PACKAGE"
echo "   X_PLATFORM: $X_PLATFORM"
echo "   SUPABASE_URL: $SUPABASE_URL"
echo ""

if [ -z "$API_KEY" ] || [ -z "$FILE_PATH" ] || [ -z "$X_APP_PACKAGE" ] || [ -z "$X_PLATFORM" ] || [ -z "$SUPABASE_URL" ]; then
  echo "❌ ERROR: Missing required inputs."
  echo "   Required variables:"
  echo "   - API_KEY: ${API_KEY:+SET}${API_KEY:-NOT SET}"
  echo "   - FILE_PATH: ${FILE_PATH:+SET}${FILE_PATH:-NOT SET}"
  echo "   - X_APP_PACKAGE: ${X_APP_PACKAGE:+SET}${X_APP_PACKAGE:-NOT SET}"
  echo "   - X_PLATFORM: ${X_PLATFORM:+SET}${X_PLATFORM:-NOT SET}"
  echo "   - SUPABASE_URL: ${SUPABASE_URL:+SET}${SUPABASE_URL:-NOT SET}"
  exit 1
fi

echo "✅ All required environment variables are set"
echo ""

# Verify file exists
echo "🔄 Verifying file..."
echo "   Checking file: $FILE_PATH"
echo ""

if [ ! -f "$FILE_PATH" ]; then
  echo "❌ ERROR: File not found at: $FILE_PATH"
  echo "   Current directory: $(pwd)"
  echo "   Directory contents:"
  ls -la "$(dirname "$FILE_PATH")" 2>/dev/null || echo "   Cannot list directory"
  exit 1
fi

FILENAME=$(basename "$FILE_PATH")
FILE_SIZE=$(ls -lh "$FILE_PATH" | awk '{print $5}')

echo "✅ File found:"
echo "   Path: $FILE_PATH"
echo "   Name: $FILENAME"
echo "   Size: $FILE_SIZE"
echo ""

# Upload file
echo "🔄 Starting upload..."
echo "   Destination: $SUPABASE_URL"
echo "   File: $FILENAME ($FILE_SIZE)"
echo "   Started at: $(date)"
echo ""

UPLOAD_START_TIME=$(date +%s)

# Perform the upload
RESPONSE=$(curl -s -X POST "$SUPABASE_URL" \
  -H "X-API-Key: $API_KEY" \
  -H "X-App-Package: $X_APP_PACKAGE" \
  -H "X-Platform: $X_PLATFORM" \
  -F "file=@$FILE_PATH" \
  -w "\n---SEPARATOR---\nHTTP_STATUS:%{http_code}\nTIME_TOTAL:%{time_total}s\nSPEED_UPLOAD:%{speed_upload} bytes/sec\n")

UPLOAD_END_TIME=$(date +%s)
UPLOAD_DURATION=$((UPLOAD_END_TIME - UPLOAD_START_TIME))

echo "📤 Upload completed at: $(date)"
echo "   Duration: ${UPLOAD_DURATION} seconds"
echo ""

# Parse response
BODY=$(echo "$RESPONSE" | sed -n '1,/---SEPARATOR---/p' | sed '$d')
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d':' -f2)
TIME_TOTAL=$(echo "$RESPONSE" | grep "TIME_TOTAL:" | cut -d':' -f2)
SPEED_UPLOAD=$(echo "$RESPONSE" | grep "SPEED_UPLOAD:" | cut -d':' -f2)

echo "📡 Upload response:"
echo "   HTTP Status: $HTTP_STATUS"
echo "   Time: $TIME_TOTAL"
echo "   Speed: $SPEED_UPLOAD"
echo ""
echo "   Response body:"
echo "$BODY"
echo ""

# Check if upload was successful (2xx status codes)
if [[ "$HTTP_STATUS" =~ ^2[0-9][0-9]$ ]]; then
  echo "✅ Upload successful!"
  
  # Set GitHub Actions outputs
  {
    echo "response<<EOF"
    echo "$BODY"
    echo "EOF"
  } >> "$GITHUB_OUTPUT"
  echo "http-status=$HTTP_STATUS" >> "$GITHUB_OUTPUT"
  
  echo ""
  echo "🎉 ========================================"
  echo "🎉 Upload completed successfully!"
  echo "🎉 ========================================"
  echo "📊 Summary:"
  echo "   File: $FILENAME"
  echo "   Size: $FILE_SIZE"
  echo "   Status: $HTTP_STATUS"
  echo "   Duration: ${UPLOAD_DURATION} seconds"
  echo "   Completed at: $(date)"
  echo ""
else
  echo "❌ ERROR: Upload failed with HTTP status $HTTP_STATUS"
  echo "   Response: $BODY"
  exit 1
fi
