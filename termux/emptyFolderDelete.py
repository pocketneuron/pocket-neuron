# POCKET NEURON empty folder deletor

import os
import json
import time
from pathlib import Path

LOG_FILE = "delete_log.json"  # Stored in the current working directory

def is_file_empty(file_path):
    """Check if a file is empty (size = 0 bytes)."""
    try:
        return os.path.getsize(file_path) == 0
    except:
        return True

def delete_empty_folders(base_dir):
    """
    Delete all empty folders or folders with only empty files.
    Creates a JSON log file for recovery.
    """
    deleted_items = []
    base_dir = os.path.abspath(base_dir)
    print(f"\n🔍 Scanning: {base_dir}\n")

    # Walk bottom-up so empty subfolders are handled first
    for root, dirs, files in os.walk(base_dir, topdown=False):
        all_files_empty = all(is_file_empty(os.path.join(root, f)) for f in files)
        folder_empty = (len(files) == 0 and len(dirs) == 0)

        if folder_empty or (all_files_empty and len(dirs) == 0):
            try:
                # Record before deleting
                item_data = {
                    "path": root,
                    "files": [],
                    "timestamp": time.time()
                }

                # Save file data if empty files exist
                for f in files:
                    file_path = os.path.join(root, f)
                    with open(file_path, "rb") as fp:
                        item_data["files"].append({
                            "name": f,
                            "data": fp.read().decode("utf-8", errors="ignore")
                        })

                deleted_items.append(item_data)

                # Delete files then folder
                for f in files:
                    os.remove(os.path.join(root, f))
                os.rmdir(root)
                print(f"🗑️ Deleted folder: {root}")

            except Exception as e:
                print(f"⚠️ Error deleting {root}: {e}")

    if deleted_items:
        # Save to log file
        with open(LOG_FILE, "w", encoding="utf-8") as log:
            json.dump(deleted_items, log, indent=2)
        print(f"\n✅ Operation complete. Log saved to: {LOG_FILE}")
    else:
        print("\n✅ No empty folders found. Nothing deleted.")

def restore_from_log():
    """Restore all deleted folders and files using the log file."""
    if not os.path.exists(LOG_FILE):
        print("❌ No log file found to restore from.")
        return

    with open(LOG_FILE, "r", encoding="utf-8") as log:
        deleted_items = json.load(log)

    print("\n♻️ Restoring deleted folders...")
    for item in deleted_items:
        folder = item["path"]
        os.makedirs(folder, exist_ok=True)

        for f in item["files"]:
            try:
                with open(os.path.join(folder, f["name"]), "w", encoding="utf-8", errors="ignore") as fp:
                    fp.write(f["data"])
            except Exception as e:
                print(f"⚠️ Error restoring file {f['name']}: {e}")

        print(f"🔄 Restored folder: {folder}")

    print("\n✅ Restore complete!")

def main():
    print("=== Empty Folder Cleaner & Restorer ===")
    print("1️⃣  Delete empty folders")
    print("2️⃣  Restore from log")
    choice = input("Choose (1/2): ").strip()

    if choice == "1":
        base = input("Enter base directory (default=Current): ").strip()
        if base == "":
            base = "."
        delete_empty_folders(base)
    elif choice == "2":
        restore_from_log()
    else:
        print("❌ Invalid choice.")

if __name__ == "__main__":
    main()