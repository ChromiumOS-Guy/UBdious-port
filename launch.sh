#!/bin/bash

# Define the Invidious instance URL
INVIDIOUS_BASE_URL="https://inv.nadeko.net"

# Define the base command for webapp-container
WEBAPP_COMMAND="webapp-container --app-id=\"ubdious.chromiumos-guy\" --enable-back-forward --store-session-cookies --webapp-name=UBdious-port --enable-media-hub-audio --webappUrlPatterns=${INVIDIOUS_BASE_URL}/*,https://*.youtube.com/*,https://youtube.com/*"

# Get the URL passed as an argument (%u)
INPUT_URL="$1"

# Function to check if a URL is a valid Invidious URL for this instance
is_valid_invidious_url() {
    local url="$1"
    [[ "$url" =~ ^https://inv\.nadeko\.net/.* ]]
}

# Function to convert YouTube URLs to Invidious URLs (now with playlist support)
convert_youtube_to_invidious() {
    local youtube_url="$1"
    local video_id
    local playlist_id

    # Extract video ID from common YouTube URL formats
    if [[ "$youtube_url" =~ v=([a-zA-Z0-9_-]{11}) ]]; then
        video_id="${BASH_REMATCH[1]}"
    elif [[ "$youtube_url" =~ youtu\.be/([a-zA-Z0-9_-]{11}) ]]; then
        video_id="${BASH_REMATCH[1]}"
    fi

    # Extract playlist ID
    if [[ "$youtube_url" =~ list=([a-zA-Z0-9_-]+) ]]; then
        playlist_id="${BASH_REMATCH[1]}"
    fi

    # Prioritize playlist if both are present, otherwise handle video, then playlist only
    if [ -n "$playlist_id" ]; then
        if [ -n "$video_id" ]; then
            # If both video and playlist, create a combined URL (Invidious handles this)
            echo "${INVIDIOUS_BASE_URL}/watch?v=${video_id}&list=${playlist_id}"
        else
            # Only playlist ID present
            echo "${INVIDIOUS_BASE_URL}/playlist?list=${playlist_id}"
        fi
    elif [ -n "$video_id" ]; then
        # Only video ID present
        echo "${INVIDIOUS_BASE_URL}/watch?v=${video_id}"
    else
        echo "" # Return empty if no valid video or playlist ID found
    fi
}

# --- Main Logic ---

if [ -z "$INPUT_URL" ]; then
    # %u is empty, run the default command
    echo "No URL provided (%u is empty). Running default Invidious instance."
    eval "$WEBAPP_COMMAND $INVIDIOUS_BASE_URL"
else
    # %u is not empty, check and process the URL
    if is_valid_invidious_url "$INPUT_URL"; then
        echo "Provided URL is already a valid Invidious URL: $INPUT_URL"
        eval "$WEBAPP_COMMAND \"$INPUT_URL\""
    elif [[ "$INPUT_URL" =~ ^https?://(www\.)?(youtube\.com|youtu\.be)/.* ]]; then
        # It's a YouTube URL, attempt to convert
        CONVERTED_URL=$(convert_youtube_to_invidious "$INPUT_URL")
        if [ -n "$CONVERTED_URL" ]; then
            echo "Converted YouTube URL to Invidious URL: $CONVERTED_URL"
            eval "$WEBAPP_COMMAND \"$CONVERTED_URL\""
        else
            echo "Could not convert YouTube URL to Invidious format: $INPUT_URL"
            echo "Running default Invidious instance."
            eval "$WEBAPP_COMMAND $INVIDIOUS_BASE_URL"
        fi
    else
        echo "Provided URL is not an Invidious URL or a YouTube URL: $INPUT_URL"
        echo "Running default Invidious instance."
        eval "$WEBAPP_COMMAND $INVIDIOUS_BASE_URL"
    fi
fi