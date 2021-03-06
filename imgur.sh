#!/bin/bash

# Created by Shaun O'Neill (XeliteXirish)
# https://www.shaunoneill.com - https://github.com/XeliteXirish

apikey="totallypublickey"

NORMAL="\033[0m"
GREEN="\033[0;32m"
RED="\033[0;31m"

# Output usage instructions
function usage {
    echo "Usage: $(basename $0) <filename> [<filename> [...]]" >&2
    echo "Upload images to imgur and output their new URLs to the console." >&2
    echo "The delete page url is also outputed to the console!" >&2
    echo "If xsel or xclip is available, the URLs are put in the console" >&2
}

# Check the API key has been entered
if [ "$apikey" = "Your API key" ]; then
    echo "You first need to edit this script and paste your API key in the variable at the top of this file!" >&2
    exit 15
fi

# Check arguments
if [ "$1" = "-h" -o "$1" = "--help" ]; then
    usage
    exit 0
elif [ $# == 0 ]; then
    echo "No file specified" >&2
    usage
    exit 16
fi

# Check curl is available
type curl >/dev/null 2>/dev/null || {
    echo "Couln't find curl, which is required. Please install it with sudo apt-get install curl" >&2
    exit 17
}

clip=""
errors=false

# Loop through arguments, so all files are uploaded
while [ $# -gt 0 ]; do
    file="$1"
    shift

    if [ ! -f "$file" ]; then
        echo "File '$file' doesn't exist, skipping" >&2
        errors=true
        continue
    fi
    echo "Uploading image.. please wait"

    # Upload the image
    response=$(curl -s -H "Authorization: Client-ID $apikey" -F "image=@$file" \https://api.imgur.com/3/upload.xml)
            
    if [ $? -ne 0 ]; then
        echo "Upload failed" >&2
        errors=true
        continue
    elif [ $(echo $response | grep -c "<error_msg>") -gt 0 ]; then
        echo "Error message from imgur:" >&2
        echo $response | sed -r 's/.*<error_msg>(.*)<\/error_msg>.*/\1/' >&2
        errors=true
        continue
    fi

    # Parse the response
    url=$(echo $response | sed -r 's/.*<link>(.*)<\/link>.*/\1/')
    deleteurl="http://i.imgur.com/delete/$(echo $response |\
 sed -r 's/.*<deletehash>(.*)<\/deletehash>.*/\1/')"
    echo -e "\n${GREEN}$url"
    echo -e "${NORMAL}Delete page: ${RED}$deleteurl" >&2

    # Append the URL to a string so we can put them all on the clipboard later
    clip="$clip$url"
done

# Put the URLs on the clipboard if xsel or xclip is available
if [ $DISPLAY ]; then
    { type xsel >/dev/null 2>/dev/null && echo -n $clip | xsel; } \
        || { type xclip >/dev/null 2>/dev/null && echo -n $clip | xclip; } \
        || echo "Haven't copied to the clipboard: no xsel or xclip" >&2
fi

if $errors; then
    exit 1
fi
