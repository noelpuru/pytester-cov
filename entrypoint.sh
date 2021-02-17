#!/bin/bash

# --- Parameters --- #
# $1: pytest-root-dir
# $2: cov-ignore-dirs
# $3: cov-threshold

# default directories to ignore testing for coverage of .py files
default_ignore_dirs="|
  pytest |
  pytest_cache |
  __pycache__ |
  test |
  tests |
  .git |
  .github"
ignore_dirs_arr=($default_ignore_dirs)

# convert directory str input to arr
ignore_dirs_input_arr=($2)

# append additional user input dirs to ignore_dirs
for dir in "${ignore_dirs_input_arr[@]}"; do
  ignore_dirs_arr[${#ignore_dirs_arr[*]}]="$dir"
done

# build grep cmd to ignore dirs
grep_ignore_dirs=""
for dir in "${ignore_dirs_arr[@]}"; do
  grep_ignore_dirs+=" | grep -v -w '${dir}'"
done

# get list of dirs to run pytest-cov on
find_cmd_str="find $1 -type d $grep_ignore_dirs"
pytest_dirs=$(eval "$find_cmd_str")

# build cov argument for pytest cmd with list of dirs
pytest_cov_dirs=""
for dir in $pytest_dirs; do
  pytest_cov_dirs+="--cov=${dir} "
done

# python3 -m pytest --cov=. tests/ --cov-fail-under=85
# python3 -m pytest --cov-config=.coveragerc --cov=. tests/
output=$(python3 -m pytest $pytest_cov_dirs --cov-fail-under=$3)

parse_title=false  # parsing title (not part of table)
parse_contents=false  # parsing contents of table
parsed_content_header=false  # finished parsing column headers of table
output_table_title=''
output_table_contents=''
item_cnt=0 # four items per row in table
items_per_row=4

for x in $output; do
  if [ "$x" = "----------------------------------------" ]; then
    continue
  fi

  if [ "$x" = "-----------" ]; then
    if [ "$parse_title" = false ]; then
      parse_title=true
    else
      output_table_title+="$x "

      parse_title=false
      parse_contents=true
      continue
    fi
  fi

  if [ "$parse_contents" = true ]; then
    if [ "$x" = "==============================" ]; then
      break
    fi
  fi

  if [ "$parse_title" = false ]; then
    if [ "$parse_contents" = false ]; then
      continue
    else
      # parse contents

      if [[ "$parsed_content_header" = false && $item_cnt = 4 ]]; then
        # needed between table headers and values for markdown
        output_table_contents+="
| ------ | ------ | ------ | ------ |"
        parsed_content_header=true
      fi

      item_cnt=$((item_cnt % items_per_row))

      if [ $item_cnt = 0 ]; then
        output_table_contents+="
"
      fi

      output_table_contents+="| $x "

      item_cnt=$((item_cnt+1))
    fi
  else
    # parse title
    output_table_title+="$x "
  fi

  output_table+="$x"
done


echo $output_table_title
# echo $output_table
echo $output_table_contents

# github actions truncates newlines, need to do replace
# https://github.com/actions/create-release/issues/25
output_table_contents="${output_table_contents//'%'/'%25'}"
output_table_contents="${output_table_contents//$'\n'/'%0A'}"
output_table_contents="${output_table_contents//$'\r'/'%0D'}"

echo "::set-output name=output-table::$output_table_contents"

time1=$(date)
echo "::set-output name=time::$time1"
echo "::set-output name=time1::$time1"
