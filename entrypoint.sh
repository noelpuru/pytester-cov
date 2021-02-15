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

parse_title=false
parse_contents=false
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
      item_cnt=$((item_cnt % items_per_row))

      if [ $item_cnt = 0 ]; then
        output_table_contents+='\n'
      fi

      output_table_contents+="$x |"

      item_cnt=$((item_cnt+1))
    fi
  else
    # parse title
    output_table_title+="$x "
  fi

  output_table+="$x"
done

echo "::set-output name=output-table::$output_table_contents"
