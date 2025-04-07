#!/bin/bash

if [ -z "$USER_ID" ] || [ $USER_ID -eq 0 ]; then
    USER_ID=1000
else
    USER_ID=$USER_ID
fi

if [ -z "$GROUP_ID" ] || [ $GROUP_ID -eq 0 ]; then
    GROUP_ID=1000
else
    GROUP_ID=$GROUP_ID
fi


# Create a new user with the specified UID
useradd -m -u $USER_ID -s /bin/bash jovyan

# Change ownership of the home directory
mkdir -p /home/jovyan/starships_data && mkdir -p /home/jovyan/.local
chown -R $USER_ID:$GROUP_ID /home/jovyan

# Switch to the new user and execute the command
exec gosu jovyan "$@"
