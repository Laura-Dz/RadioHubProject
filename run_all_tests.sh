#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "\n${BOLD}${CYAN}=================================================================${NC}"
echo -e "${BOLD}${CYAN} 1. Running Central Backend Endpoints Test Suite${NC}"
echo -e "${BOLD}${CYAN}=================================================================${NC}"
Hub/venv/bin/python scripts/test_endpoints.py

echo -e "\n${BOLD}${CYAN}=================================================================${NC}"
echo -e "${BOLD}${CYAN} 2. Running Django Unit & Crypto Tests (manage.py test)${NC}"
echo -e "${BOLD}${CYAN}=================================================================${NC}"
Hub/venv/bin/python Hub/manage.py test listener_api --verbosity=1

echo -e "\n${BOLD}${CYAN}=================================================================${NC}"
echo -e "${BOLD}${CYAN} 3. Running Static Code Analysis (Flutter / Dart)${NC}"
echo -e "${BOLD}${CYAN}=================================================================${NC}"
if command -v flutter &> /dev/null && [ -w "/opt/flutter/bin/cache" ]; then
    echo "Running flutter analyze..."
    cd radioadmin && flutter analyze && cd ..
else
    echo "Running dart analyze on RadioAdmin..."
    dart analyze --no-fatal-warnings radioadmin/lib/
fi

echo -e "\n${BOLD}${GREEN}=================================================================${NC}"
echo -e "${BOLD}${GREEN} ✓ ALL SYSTEM VERIFICATIONS PASSED SUCCESSFULLY!${NC}"
echo -e "${BOLD}${GREEN}=================================================================${NC}\n"
