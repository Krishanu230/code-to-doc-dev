#!/bin/bash

ANALYZE_NAME="analyze"
ANALYZE_DOWNLOAD_URL='https://releases.knowl.io/analyze'
GENERATOR_NAME="generate"
GENERATOR_DOWNLOAD_URL='https://releases.knowl.io/generator'
IGNORE_NAME="ignore"
IGNORE_DOWNLOAD_URL='https://releases.knowl.io/ignore'
KNOWL_UTILS_NAME="knowl-utils"
KNOWL_UTILS_DOWNLOAD_URL='https://releases.knowl.io/knowl-utils'

check_envs() {
  local unset_envs=()
  for env_var in "$@"; do
    if [[ -z "${!env_var}" ]]; then
      unset_envs+=("$env_var")
    fi
  done

  if [[ ${#unset_envs[@]} -gt 0 ]]; then
    echo "Error: The following environment variables are unset:"
    for unset_env in "${unset_envs[@]}"; do
      echo "  - $unset_env"
    done
    exit 1
  fi
}

load_env() {
  if [[ -f "$1" ]]; then
    set -o allexport
    source .env
    set +o allexport
    echo "Environment variables loaded from $1"
  fi
}

verify_wget() {
    BIN_WGET=$(which wget) || {
        echo "You need to install 'wget' to use this hook."
        exit 1
    }
}

get_abs_filename() {
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

ensure_directory_exists() {
  local directory_path="$1"

  if [ ! -d "$directory_path" ]; then
    mkdir -p "$directory_path"
    echo "Directory created: $directory_path"
  else
    echo "Directory already exists: $directory_path"
  fi
}

download_from_link() {
    echo "download begins ..."
    echo "$1"
    echo "${BIN_WGET}"
    download_url="$1"
    directory_name="$2"
    file_path="$3"
    
    ensure_directory_exists $directory_name
    $BIN_WGET --no-check-certificate $download_url -O $file_path
    chmod +x $file_path
    echo "download ends ..."
}


directory_path="$1"
if [ -z "$directory_path" ]; then
  echo "Directory path is missing."
  exit 1
fi
directory_path=$(get_abs_filename ${directory_path})
RESULT_DIR="${directory_path}/knowl_results"
SHELL_LOG_FILE=$RESULT_DIR/shell_log.txt
touch "$SHELL_LOG_FILE"
# Save the original stdout to file descriptor 3
exec 3>&1
exec > >(tee $SHELL_LOG_FILE)
#RESULT_DIR=$(get_abs_filename ${RESULT_DIR})
ANALYSED_RESULT_DIR=$RESULT_DIR/analysed
ensure_directory_exists ${RESULT_DIR}
ensure_directory_exists $ANALYSED_RESULT_DIR

verify_python() {
  if command -v python3.9 &>/dev/null; then
    echo "Python is installed."
    python_version=$(python3.9 -V 2>&1)
    echo "Python version: $python_version"
  else
    echo "Python is not installed."
    exit 1
  fi
}

verify_ts_node() {
  # Check if ts-node is installed
  if command -v ts-node &>/dev/null; then
    echo "ts-node is installed."
    
    # Check the ts-node version
    ts_node_version=$(ts-node --version 2>&1)
    echo "ts-node version: $ts_node_version"
  else
    echo "ts-node is not installed."
    exit 1
  fi
}

#./genEnv.sh
load_env ".env"
check_envs "KNOWL_BACKEND_HTTP" "REPO_NAME" "OWNER_NAME" "BRANCH_NAME" "COMMIT_SHA" "OPENAI_API_KEY" "KNOWL_API_KEY"
#verify_python
verify_ts_node
verify_wget

echo ""
echo "----getting the latest knowl tools----"
download_from_link $IGNORE_DOWNLOAD_URL ./ ./$IGNORE_NAME
download_from_link $ANALYZE_DOWNLOAD_URL ./ ./$ANALYZE_NAME
download_from_link $GENERATOR_DOWNLOAD_URL ./ ./$GENERATOR_NAME
download_from_link $KNOWL_UTILS_DOWNLOAD_URL ./ ./$KNOWL_UTILS_NAME

echo ""
echo "----bucketing files----"
./bucket_files.sh $directory_path $RESULT_DIR/buckets
exit_code_script1=$?

#step 1: bucket files
if [ $exit_code_script1 -eq 0 ]; then
  echo "bucketing files successful."
else
  echo "bucketing files failed."
  exit 1
fi

echo ""
echo "----ignoring files----"
#cd preprocessers/ignore/build
#npm i
./ignore ignore $directory_path $RESULT_DIR/buckets
exit_code2=$?
if [ $exit_code2 -eq 0 ]; then
  echo "ignore script executed successfully."
else
  echo "ignore script failed with exit code $exit_code."
  exit 1
fi
#cd ../../../

echo ""
echo "----running analysers----"
#step2 run analysers
#python3.9 -m pip install --upgrade pip
##pip install -r ./analysers/python/requirements.txt
#python3.9 analysers/python/python_docs.py  -o $RESULT_DIR/analysed -r $RESULT_DIR/buckets/py_files.json
#exit_code2=$?

#if [ $exit_code2 -eq 0 ]; then
#  echo "Python analyser executed successfully."
#else
##  echo "Python analyser failed with exit code $exit_code."
#fi

#cd analysers/ts/build
#npm i
./analyze analyze $RESULT_DIR/buckets/ts_files.json -o $RESULT_DIR/analysed
exit_code2=$?
if [ $exit_code2 -eq 0 ]; then
  echo "Ts analyser executed successfully."
else
  echo "Ts analyser failed with exit code $exit_code."
fi
#cd ../../../

echo ""
echo "----running generator----"
# Restore stdout to the console
exec 1>&3

# Close file descriptor 3
exec 3>&-
# Restoring stdout to its original state

#step3 run generator
#cd generator/
#npm i
./generate gendoc $RESULT_DIR/analysed $directory_path -f false -o $RESULT_DIR/generated/ -c true
#ts-node src/index.ts gendoc $RESULT_DIR/analysed $directory_path -f false -o $RESULT_DIR/generated/ -c true
#./generator/build/generator gendoc $RESULT_DIR/analysed $directory_path -f false -o $RESULT_DIR/generated/ -c true

exec > >(tee -a $SHELL_LOG_FILE)
echo ""
echo "----running importer----"
./knowl-utils importer $RESULT_DIR/generated/ html
