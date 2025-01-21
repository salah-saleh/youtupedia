#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'

echo -e "${BLUE}1. Testing Invalid Hosts Blocking${NC}"
echo "----------------------------------------"
hosts=(
  "evil.com"
  "attacker.com"
  "youtupedia.ai"     # Valid host
  "www.youtupedia.ai" # Valid host
  "localhost"         # Valid in development
)

for host in "${hosts[@]}"; do
  response=$(curl -s -i -w "\n%{http_code}" -H "Host: $host" http://localhost:3000/)
  status=${response: -3}
  echo -e "Host: $host - Status: ${status}"
  echo "---"
done

echo -e "\n${BLUE}2. Testing PHP/WordPress Scan Blocking${NC}"
echo "----------------------------------------"
paths=(
  "/wp-admin/setup.php"
  "/wp-content/themes/"
  "/wordpress/wp-login.php"
  "/xmlrpc.php"
  "/"  # Valid path
)

for path in "${paths[@]}"; do
  response=$(curl -s -i -w "\n%{http_code}" "http://localhost:3000$path")
  status=${response: -3}
  echo -e "Path: $path - Status: ${status}"
  echo "---"
done

echo -e "\n${BLUE}3. Testing Scanner User-Agent Blocking${NC}"
echo "----------------------------------------"
agents=(
  "sqlmap/1.0"
  "nikto/2.1.5"
  "nmap/7.80"
  "Mozilla/5.0"  # Valid user agent
)

for agent in "${agents[@]}"; do
  response=$(curl -s -i -w "\n%{http_code}" -A "$agent" http://localhost:3000/)
  status=${response: -3}
  echo -e "User-Agent: $agent - Status: ${status}"
  echo "---"
done

echo -e "\n${BLUE}4. Testing Rate Limiting${NC}"
echo "----------------------------------------"

echo "4.1 General Rate Limiting (300/5min)"
for i in {1..310}; do
  response=$(curl -s -w "%{http_code}" http://localhost:3000/)
  echo -ne "Request $i: $response\r"
  if [ "$response" = "429" ]; then
    echo -e "\nRate limit hit after $i requests!"
    break
  fi
done

echo -e "\n4.2 Login Rate Limiting (5/20sec)"
for i in {1..6}; do
  response=$(curl -s -w "%{http_code}" -X POST http://localhost:3000/session)
  echo "Login attempt $i: $response"
  sleep 0.1
done

echo -e "\n4.3 Search Rate Limiting (30/min)"
for i in {1..35}; do
  response=$(curl -s -w "%{http_code}" http://localhost:3000/search)
  echo -ne "Search request $i: $response\r"
  if [ "$response" = "429" ]; then
    echo -e "\nSearch rate limit hit after $i requests!"
    break
  fi
done

echo -e "\n4.4 GPT Rate Limiting (10/min)"
for i in {1..12}; do
  response=$(curl -s -w "%{http_code}" -X POST http://localhost:3000/summaries/1/ask_gpt)
  echo -ne "GPT request $i: $response\r"
  if [ "$response" = "429" ]; then
    echo -e "\nGPT rate limit hit after $i requests!"
    break
  fi
done

echo -e "\n${BLUE}5. Testing Fail2Ban (10 blocked requests -> 1 hour ban)${NC}"
echo "----------------------------------------"
for i in {1..12}; do
  response=$(curl -s -w "%{http_code}" -A "sqlmap/1.0" http://localhost:3000/)
  echo "Blocked request $i: $response"
  sleep 0.1
done 