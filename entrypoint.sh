#!/bin/bash

# --- Parameters --- #
# $1: pytest-root-dir
# $2: cov-omit-list
# $3: cov-threshold-single
# $4: cov-threshold-total

cov_config_fname=.coveragerc
cov_threshold_single_fail=false
cov_threshold_total_fail=false

# convert directory str input to arr
cat << EOF > $cov_config_fname
[run]
omit = $2
EOF

# get list of dirs to run pytest-cov on
find_cmd_str="find $1 -type d"
pytest_dirs=$(eval "$find_cmd_str")

# build cov argument for pytest cmd with list of dirs
pytest_cov_dirs=""
for dir in $pytest_dirs; do
  pytest_cov_dirs+="--cov=${dir} "
done

# python3 -m pytest --cov=. tests/ --cov-fail-under=85
# python3 -m pytest --cov-config=.coveragerc --cov=. tests/
output=$(python3 -m pytest $pytest_cov_dirs --cov-config=.coveragerc)

# remove pytest-coverage config file
if [ -f $cov_config_fname ]; then
   rm $cov_config_fname
fi

parse_title=false  # parsing title (not part of table)
parse_contents=false  # parsing contents of table
parsed_content_header=false  # finished parsing column headers of table
item_cnt=0 # four items per row in table
items_per_row=4

output_table_title=''
output_table_contents=''
file_covs=()
total_cov=0
skip_file=False

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
        # needed between table headers and values for markdown table
        output_table_contents+="
| ------ | ------ | ------ | ------ |"
      fi

      if [[ $item_cnt = 3 ]]; then
        # store individual file coverage
        file_covs+=( ${x::-1} )  # remove percentage at end
        total_cov=${x::-1}  # will store last one
      fi

      if [[ $item_cnt == 4 ]]; then
        parsed_content_header=true
      fi

      item_cnt=$((item_cnt % items_per_row))

      if [ $item_cnt = 0 ]; then
        output_table_contents+="
"
      fi

      output_table_contents+="| $x "

      item_cnt=$((item_cnt+1))

      if [ $item_cnt = 4 ]; then
        output_table_contents+="|"
      fi
    fi
  else
    # parse title
    output_table_title+="$x "
  fi

  output_table+="$x"
done

echo $output_table_contents

# remove last file-cov b/c it's total-cov
unset 'file_covs[${#file_covs[@]}-1]'

# remove first file-cov b/c it's table header
file_covs=("${file_covs[@]:1}") #removed the 1st element

for a in "${file_covs[@]}"; do echo "$a"; done
echo 'total_cov' $total_cov

# check if any file_cov exceeds threshold
for file_cov in "${file_covs[@]}"; do
  if [ "$file_cov" -lt $3 ]; then
    cov_threshold_single_fail=true
  fi
done

# check if total_cov exceeds threshold
if [ "$total_cov" -lt $4 ];
  then cov_threshold_total_fail=true
fi

echo 'cov-threshold-single' $3
echo 'cov-threshold-total' $4
echo 'cov_threshold_single_fail' $cov_threshold_single_fail
echo 'cov_threshold_total_fail' $cov_threshold_total_fail

echo $output_table_title
# echo $output_table
echo $output_table_contents

# github actions truncates newlines, need to do replace
# https://github.com/actions/create-release/issues/25
output_table_contents="${output_table_contents//'%'/'%25'}"
output_table_contents="${output_table_contents//$'\n'/'%0A'}"
output_table_contents="${output_table_contents//$'\r'/'%0D'}"

if [ "$cov_threshold_total_fail" = true ]; then
  $(github.Github("action@github.com", "password")pytest $pytest_cov_dirs)
fi

echo "::set-output name=output-table::$output_table_contents"
echo "::set-output name=cov-threshold-single-fail::$cov_threshold_single_fail"
echo "::set-output name=cov-threshold-total-fail::$cov_threshold_total_fail"
