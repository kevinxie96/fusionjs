# find dirname of cli.sh file
if [ -L "$0" ]
then
  BIN=$(dirname $(node -e "console.log(fs.realpathSync('$0'))"))
else
  BIN=$(dirname "$0")
fi

# find project root
findroot() {
  if [ -f "WORKSPACE" ]
  then
    echo "$PWD/"
  elif [ "$PWD" = "/" ]
  then
    echo ""
  else
    # a subshell so that we don't affect the caller's $PWD
    (cd .. && findroot)
  fi
}
ROOT=$(findroot)

# setup bazelisk
if [ ! -f "$BIN/bazelisk" ]
then
  "$NODE" "$BIN/../utils/download-bazelisk.js"
fi

# setup other binaries
"$BIN/bazelisk" run //:jazelle -- noop #2>/dev/null

NODE="$ROOT/bazel-bin/jazelle.runfiles/jazelle_dependencies/bin/node"
YARN="$ROOT/bazel-bin/jazelle.runfiles/jazelle_dependencies/bin/yarn.js"
JAZELLE="$ROOT/bazel-bin/jazelle.runfiles/jazelle/cli.js"

# if we can't find Bazel workspace, fall back to system node and jazelle's pinned yarn
if [ ! -f "$NODE" ] || [ ! -f "$YARN" ] || [ ! -f "$JAZELLE" ]
then
  # if we're in a repo, jazelle declaration in WORKSPACE is wrong, so we should error out
  if [ -f "$ROOT/WORKSPACE" ]
  then
    echo "Error: Invalid \`jazelle\` declaration in WORKSPACE file"
    exit 1
  fi
  if [ ! -f "$BIN/yarn.js" ]
  then
    "$NODE" "$BIN/../utils/download-yarn.js"
  fi
  NODE="$(which node)"
  YARN="$BIN/yarn.js"
  JAZELLE="$BIN/../cli.js"
fi

"$NODE" "$JAZELLE" $@
