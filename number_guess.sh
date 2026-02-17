#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Initialize database if needed
psql --username=freecodecamp -c "CREATE DATABASE IF NOT EXISTS number_guess" > /dev/null 2>&1

# Create table if needed
$PSQL "CREATE TABLE IF NOT EXISTS users (user_id SERIAL PRIMARY KEY, username VARCHAR(22) NOT NULL UNIQUE, games_played INT DEFAULT 0, best_game INT DEFAULT NULL)" > /dev/null 2>&1

# Prompt for username
echo "Enter your username:"
read USERNAME

# Validate username length (max 22 characters)
if [[ ${#USERNAME} -gt 22 ]]; then
  USERNAME=${USERNAME:0:22}
fi

# Check if user exists and get stats
USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username = '$USERNAME'")

if [[ -z $USER_INFO ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert new user
  $PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL)" > /dev/null
else
  # Returning user
  IFS='|' read GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate secret number between 1 and 1000
SECRET_NUMBER=$((RANDOM % 1000 + 1))
GUESS=0
GUESS_COUNT=0

# Game loop
echo "Guess the secret number between 1 and 1000:"
while true; do
  read GUESS
  
  # Validate integer input
  if ! [[ "$GUESS" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi
  
  ((GUESS_COUNT++))
  
  if [[ $GUESS -eq $SECRET_NUMBER ]]; then
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

# Update user stats
if [[ -z $BEST_GAME ]] || [[ $GUESS_COUNT -lt $BEST_GAME ]]; then
  BEST_GAME=$GUESS_COUNT
fi
$PSQL "UPDATE users SET games_played = games_played + 1, best_game = $BEST_GAME WHERE username = '$USERNAME'" > /dev/null