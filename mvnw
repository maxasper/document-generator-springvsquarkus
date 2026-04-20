#!/bin/sh
set -eu

BASE_DIR=$(
  CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
  pwd
)

WRAPPER_DIR="$BASE_DIR/.mvn/wrapper"
WRAPPER_PROPERTIES="$WRAPPER_DIR/maven-wrapper.properties"
WRAPPER_JAR="$WRAPPER_DIR/maven-wrapper.jar"
JAVA_VERSION_FILE="$BASE_DIR/.mvn/java-version"

if [ ! -f "$WRAPPER_PROPERTIES" ]; then
  echo "Missing $WRAPPER_PROPERTIES" >&2
  exit 1
fi

if [ ! -f "$WRAPPER_JAR" ]; then
  WRAPPER_URL=$(sed -n 's/^wrapperUrl=//p' "$WRAPPER_PROPERTIES" | tail -n 1)
  if [ -z "${WRAPPER_URL:-}" ]; then
    echo "wrapperUrl is not configured in $WRAPPER_PROPERTIES" >&2
    exit 1
  fi

  mkdir -p "$WRAPPER_DIR"
  echo "Downloading Maven wrapper jar from $WRAPPER_URL"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$WRAPPER_URL" -o "$WRAPPER_JAR"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$WRAPPER_URL" -O "$WRAPPER_JAR"
  else
    echo "Neither curl nor wget is available to download the Maven wrapper jar" >&2
    exit 1
  fi
fi

find_java_home_for_version() {
  requested_version=$1
  for candidate in \
    "/usr/lib/jvm/java-${requested_version}-openjdk-amd64" \
    "/usr/lib/jvm/java-1.${requested_version}.0-openjdk-amd64" \
    "/usr/lib/jvm/openjdk-${requested_version}" \
    "/usr/lib/jvm/java-${requested_version}" \
    "/Library/Java/JavaVirtualMachines/temurin-${requested_version}.jdk/Contents/Home" \
    "/Library/Java/JavaVirtualMachines/jdk-${requested_version}.jdk/Contents/Home"
  do
    if [ -x "$candidate/bin/java" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

java_major_version() {
  java_cmd=$1
  "$java_cmd" -version 2>&1 | sed -n 's/.*version "\(.*\)".*/\1/p' | head -n 1 | awk -F[.-] '
    {
      if ($1 == "1") {
        print $2;
      } else {
        print $1;
      }
    }'
}

JAVA_CMD=""
REQUESTED_JAVA_VERSION=""

if [ -f "$JAVA_VERSION_FILE" ]; then
  REQUESTED_JAVA_VERSION=$(tr -d '[:space:]' < "$JAVA_VERSION_FILE")
fi

if [ -n "${JAVA_HOME:-}" ] && [ -x "${JAVA_HOME}/bin/java" ]; then
  JAVA_CMD="${JAVA_HOME}/bin/java"
elif [ -n "${REQUESTED_JAVA_VERSION:-}" ]; then
  AUTO_JAVA_HOME=$(find_java_home_for_version "$REQUESTED_JAVA_VERSION" || true)
  if [ -n "${AUTO_JAVA_HOME:-}" ]; then
    JAVA_HOME="$AUTO_JAVA_HOME"
    export JAVA_HOME
    JAVA_CMD="$JAVA_HOME/bin/java"
    echo "Using JAVA_HOME=$JAVA_HOME from .mvn/java-version"
  else
    echo "JDK $REQUESTED_JAVA_VERSION is required by .mvn/java-version but was not found on this machine." >&2
    echo "Install JDK $REQUESTED_JAVA_VERSION or set JAVA_HOME explicitly." >&2
    exit 1
  fi
fi

if [ -z "${JAVA_CMD:-}" ]; then
  JAVA_CMD=$(command -v java || true)
fi

if [ -z "${JAVA_CMD:-}" ]; then
  echo "Java is required to run the Maven wrapper" >&2
  exit 1
fi

if [ -n "${REQUESTED_JAVA_VERSION:-}" ]; then
  ACTUAL_JAVA_VERSION=$(java_major_version "$JAVA_CMD")
  if [ "$ACTUAL_JAVA_VERSION" != "$REQUESTED_JAVA_VERSION" ]; then
    echo "JDK $REQUESTED_JAVA_VERSION is required by .mvn/java-version but the wrapper resolved Java $ACTUAL_JAVA_VERSION." >&2
    if [ -n "${JAVA_HOME:-}" ]; then
      echo "Current JAVA_HOME=$JAVA_HOME" >&2
    fi
    echo "Install JDK $REQUESTED_JAVA_VERSION or set JAVA_HOME to a matching installation." >&2
    exit 1
  fi
fi

exec "$JAVA_CMD" \
  "-Dmaven.multiModuleProjectDirectory=$BASE_DIR" \
  -classpath "$WRAPPER_JAR" \
  org.apache.maven.wrapper.MavenWrapperMain \
  "$@"
