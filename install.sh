#!/bin/sh
set -e

REPO="jackccrawford/clawmark"
CLAWMARK_HOME="${CLAWMARK_HOME:-$HOME/.clawmark}"
INSTALL_DIR="${CLAWMARK_HOME}/bin"
LIB_DIR="${CLAWMARK_HOME}/lib"

# Detect platform
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux)  os="linux" ;;
  Darwin) os="darwin" ;;
  *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac

case "$ARCH" in
  x86_64|amd64)  arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

NAME="${os}-${arch}"

# Get latest release tag
LATEST=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
if [ -z "$LATEST" ]; then
  echo "Failed to fetch latest release" >&2
  exit 1
fi

URL="https://github.com/${REPO}/releases/download/${LATEST}/clawmark-${NAME}.tar.gz"
SHA_URL="https://github.com/${REPO}/releases/download/${LATEST}/clawmark-${NAME}.tar.gz.sha256"

echo "Installing clawmark ${LATEST} (${NAME})..."

# Download to temp
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

curl -fsSL "$URL" -o "$TMPDIR/clawmark.tar.gz"
curl -fsSL "$SHA_URL" -o "$TMPDIR/clawmark.sha256" 2>/dev/null || true

# Verify checksum if available
if [ -f "$TMPDIR/clawmark.sha256" ]; then
  EXPECTED=$(cat "$TMPDIR/clawmark.sha256" | awk '{print $1}')
  if command -v sha256sum > /dev/null 2>&1; then
    ACTUAL=$(sha256sum "$TMPDIR/clawmark.tar.gz" | awk '{print $1}')
  elif command -v shasum > /dev/null 2>&1; then
    ACTUAL=$(shasum -a 256 "$TMPDIR/clawmark.tar.gz" | awk '{print $1}')
  else
    echo "  Warning: no sha256sum or shasum found, skipping verification" >&2
    ACTUAL="$EXPECTED"
  fi

  if [ "$ACTUAL" != "$EXPECTED" ]; then
    echo "Checksum verification failed!" >&2
    echo "  Expected: $EXPECTED" >&2
    echo "  Got:      $ACTUAL" >&2
    exit 1
  fi
  echo "  Checksum verified."
fi

# Extract
mkdir -p "$INSTALL_DIR"
mkdir -p "$TMPDIR/extract"
tar xzf "$TMPDIR/clawmark.tar.gz" -C "$TMPDIR/extract"
cp "$TMPDIR/extract/clawmark" "$INSTALL_DIR/"
chmod +x "${INSTALL_DIR}/clawmark"

# Install clawmark-embed if present
if [ -f "$TMPDIR/extract/clawmark-embed" ]; then
  cp "$TMPDIR/extract/clawmark-embed" "$INSTALL_DIR/"
  chmod +x "${INSTALL_DIR}/clawmark-embed"
fi

# Install bundled ONNX Runtime if present
# Linux: libonnxruntime.so.* | Mac: libonnxruntime.*.dylib
BUNDLED_LIB=""
for f in "$TMPDIR/extract"/libonnxruntime.so.* "$TMPDIR/extract"/libonnxruntime.*.dylib; do
  [ -f "$f" ] && BUNDLED_LIB="$f" && break
done

if [ -n "$BUNDLED_LIB" ]; then
  mkdir -p "$LIB_DIR"
  LIB_NAME=$(basename "$BUNDLED_LIB")
  cp "$BUNDLED_LIB" "$LIB_DIR/"

  if [ "$os" = "linux" ]; then
    # Linux symlinks
    ln -sf "$LIB_NAME" "$LIB_DIR/libonnxruntime.so"
    ln -sf "$LIB_NAME" "$LIB_DIR/libonnxruntime.so.1"
    # Wrapper script for LD_LIBRARY_PATH
    mv "${INSTALL_DIR}/clawmark" "${INSTALL_DIR}/clawmark.bin"
    cat > "${INSTALL_DIR}/clawmark" <<'WRAPPER'
#!/bin/sh
SELF="$0"; while [ -L "$SELF" ]; do SELF="$(readlink "$SELF")"; done
DIR="$(cd "$(dirname "$SELF")" && pwd)"
export LD_LIBRARY_PATH="${DIR}/../lib:${LD_LIBRARY_PATH}"
exec "${DIR}/clawmark.bin" "$@"
WRAPPER
    chmod +x "${INSTALL_DIR}/clawmark"
    # Same for clawmark-embed if present
    if [ -f "${INSTALL_DIR}/clawmark-embed" ]; then
      mv "${INSTALL_DIR}/clawmark-embed" "${INSTALL_DIR}/clawmark-embed.bin"
      cat > "${INSTALL_DIR}/clawmark-embed" <<'WRAPPER'
#!/bin/sh
SELF="$0"; while [ -L "$SELF" ]; do SELF="$(readlink "$SELF")"; done
DIR="$(cd "$(dirname "$SELF")" && pwd)"
export LD_LIBRARY_PATH="${DIR}/../lib:${LD_LIBRARY_PATH}"
exec "${DIR}/clawmark-embed.bin" "$@"
WRAPPER
      chmod +x "${INSTALL_DIR}/clawmark-embed"
    fi
  else
    # macOS: copy both versioned and unversioned dylib
    for f in "$TMPDIR/extract"/libonnxruntime*.dylib; do
      [ -f "$f" ] && cp "$f" "$LIB_DIR/"
    done
    # Wrapper script for DYLD_LIBRARY_PATH
    mv "${INSTALL_DIR}/clawmark" "${INSTALL_DIR}/clawmark.bin"
    cat > "${INSTALL_DIR}/clawmark" <<'WRAPPER'
#!/bin/sh
SELF="$0"; while [ -L "$SELF" ]; do SELF="$(readlink "$SELF")"; done
DIR="$(cd "$(dirname "$SELF")" && pwd)"
export DYLD_LIBRARY_PATH="${DIR}/../lib:${DYLD_LIBRARY_PATH}"
exec "${DIR}/clawmark.bin" "$@"
WRAPPER
    chmod +x "${INSTALL_DIR}/clawmark"
    if [ -f "${INSTALL_DIR}/clawmark-embed" ]; then
      mv "${INSTALL_DIR}/clawmark-embed" "${INSTALL_DIR}/clawmark-embed.bin"
      cat > "${INSTALL_DIR}/clawmark-embed" <<'WRAPPER'
#!/bin/sh
SELF="$0"; while [ -L "$SELF" ]; do SELF="$(readlink "$SELF")"; done
DIR="$(cd "$(dirname "$SELF")" && pwd)"
export DYLD_LIBRARY_PATH="${DIR}/../lib:${DYLD_LIBRARY_PATH}"
exec "${DIR}/clawmark-embed.bin" "$@"
WRAPPER
      chmod +x "${INSTALL_DIR}/clawmark-embed"
    fi
  fi
  echo "  Bundled ONNX Runtime installed."
fi

# Symlink to a PATH location
SYMLINK_DIR=""
if [ -d "$HOME/.local/bin" ]; then
  SYMLINK_DIR="$HOME/.local/bin"
elif [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
  SYMLINK_DIR="/usr/local/bin"
fi

if [ -n "$SYMLINK_DIR" ]; then
  ln -sf "${INSTALL_DIR}/clawmark" "$SYMLINK_DIR/clawmark"
  if [ -f "${INSTALL_DIR}/clawmark-embed" ]; then
    ln -sf "${INSTALL_DIR}/clawmark-embed" "$SYMLINK_DIR/clawmark-embed"
  fi
  echo "  Linked to ${SYMLINK_DIR}/clawmark"
fi

# Verify
if "${INSTALL_DIR}/clawmark" --version > /dev/null 2>&1; then
  VERSION=$("${INSTALL_DIR}/clawmark" --version)
  echo ""
  echo "  Installed: ${VERSION}"
  echo "  Location:  ${CLAWMARK_HOME}/"
  echo ""

  # Check if clawmark is on PATH now
  if command -v clawmark > /dev/null 2>&1; then
    echo "  Ready to use: clawmark"
  elif [ -n "$SYMLINK_DIR" ]; then
    case ":$PATH:" in
      *":${SYMLINK_DIR}:"*) echo "  Ready to use: clawmark" ;;
      *) echo "  Add to PATH: export PATH=\"${SYMLINK_DIR}:\$PATH\"" ;;
    esac
  else
    echo "  Add to PATH: export PATH=\"${INSTALL_DIR}:\$PATH\""
  fi

  echo ""
  echo "  Next: clawmark signal -c \"Hello from clawmark\" -g \"first signal\""
else
  echo "Installation failed" >&2
  exit 1
fi
