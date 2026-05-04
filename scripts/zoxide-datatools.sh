#!/usr/bin/env bash
set -euo pipefail

usage(){
  cat <<EOF
zoxide-datatools - Comprehensive zoxide database manager

Main Commands:
  $0 export       [--simple|--keep-uri|--sort] [filename]     Export to CSV for editing
  $0 import       [--merge|--replace] [filename]       Import edited CSV back
  
Backup Management:
  $0 backup                                           Create database backup
  $0 restore                                          Restore from backup
  
Power User Commands (Advanced):
  $0 getzoxide    output.txt [keywords...]           Export raw data
  $0 tocsv        [-k|--keep-uri] input.txt output.csv  Convert to full CSV
  $0 tosimplecsv  input.txt output.csv               Convert to simple CSV
  $0 totext       input.csv output.txt               Convert CSV to zoxide format
  $0 toz          input.txt output.z                 Convert to z-shell format
  $0 sort         input.txt output.txt               Sort hierarchically
  $0 import-file  [--dry-run] [--merge|--replace] file  Import any format

Examples:
  $0 export                    # Export to zoxide-data.csv for editing
  $0 import                    # Import edited zoxide-data.csv
  $0 export --simple my.csv    # Export simple CSV to custom file
  $0 import --replace my.csv   # Replace database with custom file
EOF
  exit 1
}

# ─── Helpers ────────────────────────────────────────────────────────────────────

zo_data_dir(){
  if [[ -n "${_ZO_DATA_DIR:-}" ]]; then
    echo "$_ZO_DATA_DIR"
  elif [[ "$(uname)" == "Darwin" ]]; then
    echo "$HOME/Library/Application Support/zoxide"
  else
    echo "${XDG_DATA_HOME:-$HOME/.local/share}/zoxide"
  fi
}

# Escape and quote one CSV field
quote_csv(){
  local s="${1//\"/\"\"}"
  printf '"%s"' "$s"
}

# Strip surrounding quotes and un-escape inner quotes
strip_quotes(){
  local s="$1"
  s="${s#\"}"; s="${s%\"}"
  printf '%s' "${s//\"\"/\"}"
}

# ─── Meta Functions ────────────────────────────────────────────────────────────

export_csv(){
  local output_file="zoxide-data.csv"
  local csv_options="--keep-uri"
  local sort_output=false
  local temp_txt="/tmp/zoxide_export_$$.txt"
  local temp_sorted="/tmp/zoxide_export_sorted_$$.txt"
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --simple)
        csv_options=""
        shift
        ;;
      --keep-uri|-k)
        csv_options="--keep-uri"
        shift
        ;;
      --sort|-s)
        sort_output=true
        shift
        ;;
      --help)
        echo "Usage: $0 export [--simple|--keep-uri|--sort] [filename]"
        echo "  --simple     Export to simple CSV (score,path)"
        echo "  --keep-uri   Export to full CSV with URIs (default)"
        echo "  --sort       Sort entries hierarchically"
        echo "  filename     Output file (default: zoxide-data.csv)"
        return 0
        ;;
      *)
        output_file="$1"
        shift
        ;;
    esac
  done
  
  # Clean up temp files on exit
  trap 'rm -f "$temp_txt" "$temp_sorted" 2>/dev/null || true' RETURN
  
  echo "Exporting zoxide database to CSV..."
  
  # Step 1: Export from zoxide
  if ! getzoxide "$temp_txt"; then
    echo "Error: Failed to export from zoxide" >&2
    return 1
  fi
  
  # Step 2: Sort if requested
  local source_file="$temp_txt"
  if [[ "$sort_output" == true ]]; then
    echo "Sorting entries hierarchically..."
    if ! sort_hier "$temp_txt" "$temp_sorted"; then
      echo "Error: Failed to sort data" >&2
      return 1
    fi
    source_file="$temp_sorted"
  fi
  
  local entry_count=$(wc -l < "$source_file" 2>/dev/null || echo 0)
  
  # Step 3: Convert to CSV
  if [[ "$csv_options" == "--keep-uri" ]]; then
    if ! paths_to_csv yes "$source_file" "$output_file"; then
      echo "Error: Failed to convert to CSV" >&2
      return 1
    fi
    local format_desc="full CSV with URIs"
  else
    if ! paths_to_simple_csv "$source_file" "$output_file"; then
      echo "Error: Failed to convert to simple CSV" >&2
      return 1
    fi
    local format_desc="simple CSV"
  fi
  
  if [[ "$sort_output" == true ]]; then
    echo "Exported $entry_count entries to $output_file ($format_desc, sorted)"
  else
    echo "Exported $entry_count entries to $output_file ($format_desc)"
  fi
  
  echo
  echo "Next steps:"
  echo "  1. Edit $output_file in your favorite spreadsheet application"
  echo "  2. Run: $0 import [filename] to import your changes"
}

import_csv(){
  local import_file="zoxide-data.csv"
  local mode=""
  local dry_run=false
  local temp_cleanup=true
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --merge)
        mode="merge"
        shift
        ;;
      --replace)
        mode="replace"
        shift
        ;;
      --dry-run)
        dry_run=true
        shift
        ;;
      --help)
        echo "Usage: $0 import [--merge|--replace] [--dry-run] [filename]"
        echo "  --merge      Merge with existing data (default)"
        echo "  --replace    Replace entire database"
        echo "  --dry-run    Preview changes without importing"
        echo "  filename     Import file (default: zoxide-data.csv)"
        return 0
        ;;
      *)
        import_file="$1"
        shift
        ;;
    esac
  done
  
  # Check if file exists
  if [[ ! -f "$import_file" ]]; then
    echo "Error: Import file not found: $import_file" >&2
    echo "Tip: Run '$0 export' first to create the file" >&2
    return 1
  fi
  
  echo "Importing from $import_file..."
  
  # If mode not specified, ask user
  if [[ -z "$mode" && "$dry_run" == false ]]; then
    echo
    echo "Choose import mode:"
    echo "  [M]erge - Add/update entries, keep existing data (safer)"
    echo "  [R]eplace - Replace entire database with import data"
    echo
    read -p "Import mode (M/r): " -n 1 -r
    echo
    
    case ${REPLY:-M} in
      [Rr])
        mode="replace"
        echo "Replace mode selected - will remove paths not in import file"
        ;;
      *)
        mode="merge"
        echo "Merge mode selected - will add/update entries"
        ;;
    esac
  fi
  
  # Set default mode if still empty (for dry-run)
  if [[ -z "$mode" ]]; then
    mode="merge"
  fi
  
  # Build import arguments
  local import_args=()
  if [[ "$dry_run" == true ]]; then
    import_args+=("--dry-run")
  fi
  import_args+=("--$mode")
  import_args+=("$import_file")
  
  # Call the underlying import function
  if import_file "${import_args[@]}"; then
    if [[ "$dry_run" == false ]]; then
      echo
      echo "Import completed successfully!"
      
      # Ask about backup cleanup
      echo
      read -p "Remove the backup file created during import? [y/N]: " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        local zo_data_dir="$(zo_data_dir)"
        rm -f "$zo_data_dir/db.zo.backup" 2>/dev/null || true
        echo "Backup removed"
      else
        echo "Backup preserved for safety"
      fi
    fi
  else
    echo "Import failed" >&2
    return 1
  fi
}

# ─── Mode: tocsv ────────────────────────────────────────────────────────────────

paths_to_csv(){
  local keep_uri="$1"; shift
  local input="$1" output="$2"
  : > "$output"
  while IFS=$'\t' read -r raw_score raw_path; do
    [[ -z "$raw_score" ]] && continue

    # Trim score and path
    score="${raw_score#"${raw_score%%[![:space:]]*}"}"
    score="${score%"${score##*[![:space:]]}"}"
    path="${raw_path#"${raw_path%%[![:space:]]*}"}"
    path="${path%"${path##*[![:space:]]}"}"
    path="${path#/}"

    # Split into segments
    IFS='/' read -r -a parts <<< "$path"

    quote_csv "$score" >>"$output"
    if [[ "$keep_uri" == yes ]]; then
      printf ',' >>"$output"
      quote_csv "/$path" >>"$output"
    fi
    for seg in "${parts[@]}"; do
      printf ',' >>"$output"
      quote_csv "$seg" >>"$output"
    done
    printf '\n' >>"$output"
  done <"$input"
}

# ─── Mode: tosimplecsv ──────────────────────────────────────────────────────────

paths_to_simple_csv(){
  local input="$1" output="$2"
  : > "$output"
  while IFS=$'\t' read -r raw_score raw_path; do
    [[ -z "$raw_score" ]] && continue

    # Trim score and path
    score="${raw_score#"${raw_score%%[![:space:]]*}"}"
    score="${score%"${score##*[![:space:]]}"}"
    path="${raw_path#"${raw_path%%[![:space:]]*}"}"
    path="${path%"${path##*[![:space:]]}"}"

    # Simple CSV: just score and full path
    printf '%s,%s\n' "$(quote_csv "$score")" "$(quote_csv "$path")" >>"$output"
  done <"$input"
}

# ─── Mode: fromsimplecsv ────────────────────────────────────────────────────────

simple_csv_to_paths(){
  local input="$1" output="$2"
  : > "$output"
  while IFS=',' read -r raw_score raw_path; do
    [[ -z "$raw_score" ]] && continue
    
    # Strip quotes and convert to autojump format
    score=$(strip_quotes "$raw_score")
    path=$(strip_quotes "$raw_path")
    
    printf '%s\t%s\n' "$score" "$path" >> "$output"
  done < "$input"
}

# ─── Mode: totext ───────────────────────────────────────────────────────────────

csv_to_paths(){
  awk -F',' '
    function strip(s){ gsub(/^"|"$/, "", s); gsub(/""/,"\"",s); return s }
    {
      s = strip($1)+0
      # detect URI
      if (strip($2) ~ /^\// && NF>2) {
        uri = strip($2); start=3
      } else {
        uri=""; start=2
      }
      path=""
      for(i=start;i<=NF;i++){
        f=strip($i)
        if(f!="") path=path"/"f
      }
      if(path=="") path="/"
      printf("%.1f\t%s\n", s, uri?uri:path)
    }
  ' "$1" > "$2"
}


# ─── Mode: sort ─────────────────────────────────────────────────────────────────

sort_hier(){
  local input="$1"; local output="$2"
  # depth<TAB>path<TAB>score
  awk -F$'\t' '{
    d = split($2, a, "/") - 1
    printf "%d\t%s\t%s\n", d, $2, $1
  }' "$input" \
  | sort -t $'\t' -k1,1n -k2,2 \
  | awk -F$'\t' '{ print $3 "\t" $2 }' \
  > "$output"
}

# ─── Mode: toz ──────────────────────────────────────────────────────────────────

toz(){
  local input="$1" output="$2"
  : > "$output"
  while IFS=$'\t' read -r score path; do
    [[ -z "$score" ]] && continue
    # Fallback if no tab
    if [[ -z "$path" ]]; then
      read -r score path <<< "$score"
    fi
    # Convert score to z format (multiply by 4) and add timestamp placeholder
    local z_score=$((${score%.*} * 4))
    printf '%s|%s|1\n' "$path" "$z_score" >> "$output"
  done < "$input"
}

# ─── Mode: backup ───────────────────────────────────────────────────────────────

backup(){
  local zo_data_dir="$(zo_data_dir)"
  local db_file="$zo_data_dir/db.zo"
  local backup_file="$zo_data_dir/db.zo.backup"
  
  if [[ ! -f "$db_file" ]]; then
    echo "Error: zoxide database not found at $db_file" >&2
    exit 1
  fi
  
  # If backup already exists, preserve it with datetime suffix
  if [[ -f "$backup_file" ]]; then
    local datetime=$(date +"%Y%m%d_%H%M%S")
    local dated_backup="$zo_data_dir/db.zo.backup.$datetime"
    mv "$backup_file" "$dated_backup"
    echo "Existing backup moved to $dated_backup"
  fi
  
  cp "$db_file" "$backup_file"
  echo "Backed up $db_file to $backup_file"
}

# ─── Mode: restore ──────────────────────────────────────────────────────────────

restore(){
  local zo_data_dir="$(zo_data_dir)"
  local db_file="$zo_data_dir/db.zo"
  local backup_file="$zo_data_dir/db.zo.backup"
  
  if [[ ! -f "$backup_file" ]]; then
    echo "Error: backup file not found at $backup_file" >&2
    exit 1
  fi
  
  cp "$backup_file" "$db_file"
  echo "Restored $backup_file to $db_file"
}

# ─── Mode: import ───────────────────────────────────────────────────────────────

detect_format(){
  local file="$1"
  local sample_lines=5
  local format="unknown"
  
  # Read first few lines to detect format
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    
    # Z format: path|score|timestamp
    if [[ "$line" =~ ^[^|]+\|[0-9]+\|[0-9]+$ ]]; then
      format="z"
      break
    fi
    
    # Autojump format: score<TAB>path
    if [[ "$line" =~ ^[0-9]+(\.[0-9]+)?[[:space:]]+/ ]]; then
      format="autojump"
      break
    fi
    
    # Simple CSV format: "score","path" (exactly 2 fields, quoted)
    if [[ "$line" =~ ^\"[^\"]*\",\"[^\"]*\"$ ]]; then
      format="simplecsv"
      break
    fi
    
    # Simple CSV format: score,path (exactly 2 fields, unquoted)
    if [[ "$line" =~ ^[^,]+,[^,]+$ ]] && [[ $(echo "$line" | grep -o ',' | wc -l) -eq 1 ]]; then
      format="simplecsv"
      break
    fi
    
    # Full CSV format: starts with quoted score, has multiple comma-separated quoted fields  
    if [[ "$line" =~ ^\"[^\"]*\",(\"[^\"]*\",){2,} ]]; then
      format="fullcsv"
      break
    fi
    
    # Full CSV format: unquoted, has 3+ comma-separated fields starting with number
    if [[ "$line" =~ ^[0-9]+(\.[0-9]+)?, ]] && [[ $(echo "$line" | grep -o ',' | wc -l) -ge 2 ]]; then
      format="fullcsv"
      break
    fi
  done < <(head -n "$sample_lines" "$file")
  
  echo "$format"
}

import_file(){
  local dry_run=false
  local mode="merge"
  local import_file=""
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --dry-run)
        dry_run=true
        shift
        ;;
      --merge)
        mode="merge"
        shift
        ;;
      --replace)
        mode="replace"
        shift
        ;;
      *)
        import_file="$1"
        shift
        ;;
    esac
  done
  
  if [[ -z "$import_file" ]]; then
    echo "Error: Import file required" >&2
    exit 1
  fi
  
  if [[ ! -f "$import_file" ]]; then
    echo "Error: Import file not found: $import_file" >&2
    exit 1
  fi
  
  # Detect format
  local format=$(detect_format "$import_file")
  if [[ "$format" == "unknown" ]]; then
    echo "Error: Unsupported file format. Only z, autojump, simple CSV, and full CSV formats supported." >&2
    exit 1
  fi
  
  echo "Detected format: $format"
  
  # Create backup unless dry run
  if [[ "$dry_run" == false ]]; then
    echo "Creating backup..."
    backup
  fi
  
  # Get current database state
  local current_db="/tmp/zoxide_current_$$.txt"
  local import_count=0
  local current_count=0
  
  echo "Analyzing current database..."
  getzoxide "$current_db" 2>/dev/null || true
  current_count=$(wc -l < "$current_db" 2>/dev/null || echo 0)
  import_count=$(wc -l < "$import_file")
  
  # Clean up temp file when done
  rm -f "$current_db" 2>/dev/null || true
  
  echo
  echo "Import Summary:"
  echo "  Import file: $import_count entries ($format format)"
  echo "  Current database: $current_count entries"
  echo "  Mode: $mode"
  
  if [[ "$mode" == "replace" ]]; then
    echo "  Warning: Replace mode will remove paths not in import file"
  fi
  
  if [[ "$dry_run" == true ]]; then
    echo
    echo "DRY RUN - No changes will be made"
    return 0
  fi
  
  # Confirm with user
  echo
  read -p "Continue with import? [y/N]: " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Import cancelled"
    return 0
  fi
  
  # Perform import based on format and mode
  echo "Importing..."
  
  if [[ "$format" == "z" ]]; then
    # Z format always clears database first to avoid score doubling
    echo "Clearing database for z format import..."
    while IFS= read -r path; do
      zoxide remove "$path" 2>/dev/null || true
    done < <(zoxide query --list --all)
    
    # Import z format
    if ! zoxide import --from=z "$import_file"; then
      echo "Error: Import failed, restoring backup..." >&2
      restore
      exit 1
    fi
  elif [[ "$format" == "simplecsv" ]]; then
    # Simple CSV format - convert to z format to preserve scores
    local temp_autojump="/tmp/zoxide_simplecsv_$$.txt"
    local temp_z="/tmp/zoxide_simplecsv_z_$$.z"
    
    simple_csv_to_paths "$import_file" "$temp_autojump"
    toz "$temp_autojump" "$temp_z"
    
    # Z format always clears database first to avoid score doubling
    echo "Clearing database for z format import..."
    while IFS= read -r path; do
      zoxide remove "$path" 2>/dev/null || true
    done < <(zoxide query --list --all)
    
    if ! zoxide import --from=z "$temp_z"; then
      echo "Error: Import failed, restoring backup..." >&2
      rm -f "$temp_autojump" "$temp_z" 2>/dev/null || true
      restore
      exit 1
    fi
    
    rm -f "$temp_autojump" "$temp_z" 2>/dev/null || true
  elif [[ "$format" == "fullcsv" ]]; then
    # Full CSV format - convert to z format to preserve scores
    local temp_autojump="/tmp/zoxide_fullcsv_$$.txt"
    local temp_z="/tmp/zoxide_fullcsv_z_$$.z"
    
    csv_to_paths "$import_file" "$temp_autojump"
    toz "$temp_autojump" "$temp_z"
    
    # Z format always clears database first to avoid score doubling
    echo "Clearing database for z format import..."
    while IFS= read -r path; do
      zoxide remove "$path" 2>/dev/null || true
    done < <(zoxide query --list --all)
    
    if ! zoxide import --from=z "$temp_z"; then
      echo "Error: Import failed, restoring backup..." >&2
      rm -f "$temp_autojump" "$temp_z" 2>/dev/null || true
      restore
      exit 1
    fi
    
    rm -f "$temp_autojump" "$temp_z" 2>/dev/null || true
  else
    # Autojump format
    local merge_flag=""
    if [[ "$mode" == "merge" ]]; then
      merge_flag="--merge"
    fi
    
    if [[ "$mode" == "replace" ]]; then
      echo "Clearing database for replace mode..."
      zoxide query --list --all | while read -r path; do
        zoxide remove "$path" 2>/dev/null || true
      done
    fi
    
    if ! zoxide import --from=autojump $merge_flag "$import_file"; then
      echo "Error: Import failed, restoring backup..." >&2
      restore
      exit 1
    fi
  fi
  
  # Generate report
  local final_count=0
  getzoxide "/tmp/zoxide_final_$$.txt" 2>/dev/null || true
  final_count=$(wc -l < "/tmp/zoxide_final_$$.txt" 2>/dev/null || echo 0)
  
  echo
  echo "Import completed successfully!"
  echo "Final database: $final_count entries"
  
  if [[ $final_count -gt $current_count ]]; then
    echo "Added: $((final_count - current_count)) entries"
  elif [[ $final_count -lt $current_count ]]; then
    echo "Removed: $((current_count - final_count)) entries"
  else
    echo "Updated existing entries"
  fi
}

# ─── Mode: getzoxide ────────────────────────────────────────────────────────────

getzoxide(){
  local output="$1"; shift
  local tmp="$(mktemp)"
  
  zoxide query --list --all --score "$@" > "$tmp"

  : > "$output"
  while IFS=$'\t' read -r score path; do
    [[ -z "$score" ]] && continue
    # Fallback if no tab
    if [[ -z "$path" ]]; then
      read -r score path <<< "$score"
    fi
    printf '%s\t%s\n' "$score" "$path" >> "$output"
  done < "$tmp"
  
  rm -f "$tmp" 2>/dev/null || true
}

# ─── Dispatch ──────────────────────────────────────────────────────────────────

case "${1:-}" in
  export)
    export_csv "${@:2}"
    ;;
  import)
    import_csv "${@:2}"
    ;;
  tocsv)
    if [[ "$2" == "--keep-uri" || "$2" == "-k" ]]; then
      paths_to_csv yes "$3" "$4"
    else
      paths_to_csv no  "$2" "$3"
    fi
    ;;
  tosimplecsv)
    paths_to_simple_csv "$2" "$3"
    ;;
  totext)
    csv_to_paths "$2" "$3"
    ;;
  sort)
    sort_hier "$2" "$3"
    ;;
  toz)
    toz "$2" "$3"
    ;;
  backup)
    backup
    ;;
  restore)
    restore
    ;;
  import-file)
    import_file "${@:2}"
    ;;
  getzoxide)
    getzoxide "$2" "${@:3}"
    ;;
  *)
    usage
    ;;
esac
