#!/bin/bash

directory="$1"
results_directory="$2"

# Check if directory path is provided
if [ -z "$directory" ]; then
  echo "Directory path is missing."
  exit 1
fi

# Check if directory exists
if [ ! -d "$directory" ]; then
  echo "Directory does not exist: $directory"
  exit 1
fi

mkdir -p "$results_directory"

ts_json_file="${results_directory}/ts_files.json"
py_json_file="${results_directory}/py_files.json"

bucket_files=($ts_json_file $py_json_file)

declare -A extensions
extensions["ts"]=$ts_json_file
extensions["tsx"]=$ts_json_file
extensions["js"]=$ts_json_file
extensions["py"]=$py_json_file

for json_file in "${extensions[@]}"; do
    echo "{" > "$json_file"
    echo "  \"files\": [" >> "$json_file"
done

process_files() {
    local dir="$1"
    for file_path in "$dir"/*; do
        if [ -f "$file_path" ]; then
            extension="${file_path##*.}"
            if [ ${extensions[$extension]+_} ]; then
                echo "    \"$(readlink -f $file_path)\"," >> "${extensions[$extension]}"
            fi
        elif [ -d "$file_path" ]; then
            process_files "$file_path"
        fi
    done
}

process_files "$directory"

for json_file in "${bucket_files[@]}"; do
    sed -i '$ s/,$//' "$json_file"
    echo "  ]" >> "$json_file"
    echo "}" >> "$json_file"
done

echo "Files bucketed successfully!"
exit 0
