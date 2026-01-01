#!/usr/bin/env bash
# MLEnv Installation Test Suite

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

test_pass() {
  echo -e "${GREEN}✔${NC} $1"
  ((TESTS_PASSED++))
}

test_fail() {
  echo -e "${RED}✖${NC} $1"
  ((TESTS_FAILED++))
}

test_skip() {
  echo -e "${YELLOW}⊘${NC} $1"
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MLEnv Installation Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: NGC command exists
echo "Test 1: NGC command exists"
if command -v mlenv >/dev/null 2>&1; then
  test_pass "mlenv command found in PATH"
else
  test_fail "mlenv command not found in PATH"
fi
echo ""

# Test 2: NGC is executable
echo "Test 2: NGC is executable"
if [ -x "$(command -v mlenv)" ]; then
  test_pass "ngc is executable"
else
  test_fail "ngc is not executable"
fi
echo ""

# Test 3: NGC help works
echo "Test 3: NGC help command"
if mlenv help >/dev/null 2>&1; then
  test_pass "mlenv help works"
else
  test_fail "mlenv help failed"
fi
echo ""

# Test 4: Docker is available
echo "Test 4: Docker availability"
if command -v docker >/dev/null 2>&1; then
  test_pass "Docker command found"
  if docker info >/dev/null 2>&1; then
    test_pass "Docker daemon is running"
  else
    test_fail "Docker daemon is not running"
  fi
else
  test_fail "Docker not found"
fi
echo ""

# Test 5: NVIDIA runtime
echo "Test 5: NVIDIA Container Toolkit"
if docker info 2>/dev/null | grep -q "Runtimes:.*nvidia"; then
  test_pass "NVIDIA runtime detected"
else
  test_fail "NVIDIA runtime not detected"
fi
echo ""

# Test 6: Shell completions
echo "Test 6: Shell completions"
SHELL_TYPE="$(basename "$SHELL")"
case "$SHELL_TYPE" in
  bash)
    if [ -f "/etc/bash_completion.d/ngc" ] || [ -f "/usr/local/etc/bash_completion.d/ngc" ] || [ -f "$HOME/.bash_completion.d/ngc" ]; then
      test_pass "Bash completion found"
    else
      test_skip "Bash completion not found (optional)"
    fi
    ;;
  zsh)
    if [ -f "/usr/local/share/zsh/site-functions/_ngc" ] || [ -f "$HOME/.zsh/completion/_ngc" ]; then
      test_pass "Zsh completion found"
    else
      test_skip "Zsh completion not found (optional)"
    fi
    ;;
  fish)
    if [ -f "$HOME/.config/fish/completions/ngc.fish" ]; then
      test_pass "Fish completion found"
    else
      test_skip "Fish completion not found (optional)"
    fi
    ;;
  *)
    test_skip "Shell completions (unknown shell: $SHELL_TYPE)"
    ;;
esac
echo ""

# Test 7: Test container lifecycle (if Docker works)
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "Test 7: Container lifecycle (dry run)"
  
  # Create test directory
  TEST_DIR="/tmp/ngc-test-$$"
  mkdir -p "$TEST_DIR"
  cd "$TEST_DIR"
  
  # Test status command
  if mlenv status >/dev/null 2>&1; then
    test_pass "mlenv status works"
  else
    test_fail "mlenv status failed"
  fi
  
  # Cleanup
  cd - >/dev/null
  rm -rf "$TEST_DIR"
else
  test_skip "Container lifecycle test (Docker not available)"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✔ All critical tests passed!${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Create a test project: mkdir ~/ngc-test && cd ~/ngc-test"
  echo "  2. Start a container: mlenv up"
  echo "  3. Enter the container: mlenv exec"
  echo "  4. Try GPU access: nvidia-smi"
  exit 0
else
  echo -e "${RED}✖ Some tests failed${NC}"
  echo ""
  echo "Please fix the issues above before using NGC."
  exit 1
fi