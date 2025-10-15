#!/usr/bin/env bash
# =====================================================
# FILE MOVER — Smart Organizer with Undo Feature ✨
# =====================================================
# Author: Praveen + GPT-5 Innovation Duo 🚀
# Usage:
#   ./file_mover.sh /path/to/folder [--deep]
#   ./file_mover.sh --undo
# =====================================================

set -e

LOG_FILE="$HOME/.file_mover_log.txt"

# ---------- UNDO MODE ----------
if [[ "$1" == "--undo" ]]; then
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "❌ No previous move log found. Nothing to undo."
        exit 1
    fi

    echo "🧭 Undoing last organization..."
    # Reverse read log and move back files
    tac "$LOG_FILE" | while IFS='|' read -r src dest; do
        if [[ -f "$dest" ]]; then
            dir="$(dirname "$src")"
            mkdir -p "$dir"
            mv -f "$dest" "$src" 2>/dev/null && echo "↩️  Restored: $(basename "$dest")"
        fi
    done

    rm -f "$LOG_FILE"
    echo "✅ Undo complete. All files restored to original locations!"
    exit 0
fi

# ---------- NORMAL MODE ----------
TARGET_DIR="${1:-.}"
DEEP_SCAN=false
if [[ "$2" == "--deep" ]]; then DEEP_SCAN=true; fi

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "❌ Error: Directory not found: $TARGET_DIR"
    exit 1
fi

# Clean old log
> "$LOG_FILE"

declare -A CATEGORY_MAP=(
  ["jpg"]="Images" ["jpeg"]="Images" ["png"]="Images" ["gif"]="Images" ["webp"]="Images"
  ["mp4"]="Videos" ["mkv"]="Videos" ["mov"]="Videos" ["avi"]="Videos" ["webm"]="Videos"
  ["mp3"]="Audio" ["wav"]="Audio" ["m4a"]="Audio" ["aac"]="Audio" ["ogg"]="Audio"
  ["pdf"]="PDFs" ["doc"]="Documents" ["docx"]="Documents" ["txt"]="Documents" ["ppt"]="Documents" ["pptx"]="Documents"
  ["xls"]="Documents" ["xlsx"]="Documents" ["csv"]="Documents"
  ["zip"]="Archives" ["rar"]="Archives" ["tar"]="Archives" ["gz"]="Archives" ["7z"]="Archives"
  ["apk"]="APKs"
  ["py"]="Code" ["java"]="Code" ["cpp"]="Code" ["html"]="Code" ["css"]="Code" ["js"]="Code" ["php"]="Code"
)

echo "📁 Organizing: $TARGET_DIR"
echo "🔍 Scan: $([[ $DEEP_SCAN == true ]] && echo "Deep" || echo "Top-level only")"
echo "--------------------------------------"

if $DEEP_SCAN; then
  FIND_CMD="find \"$TARGET_DIR\" -type f"
else
  FIND_CMD="find \"$TARGET_DIR\" -maxdepth 1 -type f"
fi

eval $FIND_CMD | while read -r file; do
  filename="$(basename "$file")"
  ext="${filename##*.}"
  ext_lower="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
  [[ "$filename" == "$ext" ]] && continue

  folder="${CATEGORY_MAP[$ext_lower]:-Others}"
  dest_dir="$TARGET_DIR/$folder"
  mkdir -p "$dest_dir"

  new_path="$dest_dir/$filename"
  mv -n "$file" "$new_path" 2>/dev/null || mv -b "$file" "$new_path" 2>/dev/null
  echo "$file|$new_path" >> "$LOG_FILE"
  echo "➡️  $filename → $folder/"
done

echo "--------------------------------------"
echo "✅ Done! Undo info saved at: $LOG_FILE"
echo "🕹️  To undo this action: ./file_mover.sh --undo"
