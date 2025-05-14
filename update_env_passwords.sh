#!/bin/bash

# Check if pwgen is installed
if ! command -v pwgen &> /dev/null
then
    echo "pwgen is not installed. Install it using: brew install pwgen"
    exit 1
fi

# Path to the .env file
ENV_FILE=".env"

# Check if the .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "The file $ENV_FILE does not exist."
    exit 1
fi

# Check for delete option
DELETE_PASSWORDS=false
if [[ "$1" == "--delete" ]]; then
    DELETE_PASSWORDS=true
    echo "Passwords will be deleted (set to empty string)."
fi

# Update variables containing PASSWORD or SECRET
while IFS= read -r line; do
    if [[ $line == *PASSWORD=* || $line == *SECRET=* ]]; then
        VAR_NAME=$(echo "$line" | cut -d'=' -f1)
        if [ "$DELETE_PASSWORDS" = true ]; then
            NEW_PASSWORD=""
        else
            NEW_PASSWORD=$(pwgen 16 1)
        fi
        echo "Updating $VAR_NAME"
        sed -i '' "s|^$VAR_NAME=.*|$VAR_NAME=$NEW_PASSWORD|" "$ENV_FILE"
    fi
done < "$ENV_FILE"

echo "Variables in $ENV_FILE have been updated."
