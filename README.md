# README.md

```markdown
# Lab 2 - Simple Antivirus Daemon

A simplified antivirus system written in Bash that monitors a directory,
quarantines files matching flagged extensions or keywords, and lets the
user review quarantined files to restore or delete them.

## Folder Hierarchy

9773-lab2/
├── antivirusd.sh        # Antivirus daemon (Part 1)
├── restore.sh           # Interactive restore tool (Part 2)
├── antivirus-cron.sh    # Single-pass scanner for cron (Bonus 1)
├── Makefile             # Build/run targets (Part 3)
├── README.md            # This file
├── whitelist.txt        # Auto-created; stores restored files (Bonus 2)
├── monitored/           # Example source directory
├── quarantine/          # malicious_dir
├── directory-info.last  # Auto-generated snapshot
└── directory-info.new   # Auto-generated snapshot

## Prerequisites

All required tools are already installed on a standard Ubuntu system:

- `bash`
- `coreutils` (ls, cp, mv, rm, cmp, sleep)
- `grep`
- `make`

If anything is missing, install with:

```bash
sudo apt update
sudo apt install -y bash coreutils grep make
```

## How to Run the Antivirus Daemon

Using the Makefile:

```bash
make antivirus dir=monitored malicious_dir=quarantine interval=5
```

Or directly:

```bash
chmod +x antivirusd.sh
./antivirusd.sh monitored quarantine 5
```

Behavior:

1. On the very first run, the script scans `dir` immediately and saves a
   snapshot to `directory-info.last`.
2. Then, every `interval` seconds, it takes a new snapshot
   (`directory-info.new`) and compares it to the last one using `cmp`.
3. If nothing changed, it waits and checks again — no scan is performed.
4. If something changed, it scans every file directly inside `dir` and
   quarantines malicious ones.

For each malicious file found, the daemon:

- Prints `"<file> is malicious and it is DELETED"`
- Copies it into `malicious_dir` (keeping its original name)
- Deletes the original from `dir`

## How to Run the Restore Tool

Stop the daemon first (Ctrl+C), then:

```bash
make restore dir=monitored malicious_dir=quarantine
```

Or directly:

```bash
chmod +x restore.sh
./restore.sh monitored quarantine
```

The tool loops through the following steps:

1. Lists all files currently in `malicious_dir` with numbers.
2. Asks you to pick one by number (or `0` to quit).
3. For the selected file, offers three options:

   - `1` — Restore it back into `dir` (false positive)
   - `2` — Permanently delete it (genuinely malicious)
   - `3` — Leave it as-is and return to the list

Logs printed:

- `Restored <file> to <dir>.` — after option 1
- `<file> permanently deleted.` — after option 2
- `No malicious files to review.` — if `malicious_dir` is empty at start

## Where the Flagged Lists Are Defined

Both lists are hardcoded at the top of `antivirusd.sh`:

```bash
flagged_ext=(".exe" ".bat" ".vbs" ".scr" ".ps1")
flagged_kw=("virus" "trojan" "malware" "worm" "ransomware")
```

- Extension matching is exact (e.g. `.exe`).
- Content matching uses `grep -qi` so it is case-insensitive.

## Whitelist (Bonus 2)

- **Location:** `whitelist.txt` in the project root (one filename per line).
- **Added by:** `restore.sh` when the user selects option `1` (Restore).
- **Checked by:** `antivirusd.sh` inside `is_malicious()` — the first thing
  it does is check if the filename exists in `whitelist.txt`. If yes, the
  file is skipped entirely, even if its extension or content matches a
  flagged rule.
- **Persistence:** the whitelist file lives on disk, so it survives daemon
  restarts.

Example content of `whitelist.txt`:

```
notes.txt
readme.ps1
```

## Cron Job (Bonus 1)

`antivirus-cron.sh` performs a single scan pass and exits — no infinite
loop, suitable for cron scheduling.

### Prerequisites

- `cron` installed and running:

  ```bash
  sudo apt install -y cron
  sudo systemctl enable --now cron
  ```

- The script must be executable.
- Use absolute paths inside the crontab entry.

### Step-by-step

1. Make the script executable:

   ```bash
   chmod +x antivirus-cron.sh
   ```

2. Open your crontab:

   ```bash
   crontab -e
   ```

3. Add this line to run the scan every minute:

   ```
   * * * * * /absolute/path/antivirus-cron.sh /absolute/path/monitored /absolute/path/quarantine >> /absolute/path/cron.log 2>&1
   ```

4. Verify the schedule:

   ```bash
   crontab -l
   ```

### Cron expression for "every 3rd Friday of the month at 12:31 AM"

```
31 0 * * 5#3
```

- `31` — minute 31
- `0` — hour 0 (12:31 AM)
- `*` — every day of month
- `*` — every month
- `5#3` — the 3rd Friday (`5` = Friday, `#3` = third occurrence)

## Testing

Create a test file to trigger the daemon:

```bash
echo "this file contains a virus" > monitored/test.txt
```

Expected output:

```
test.txt is malicious and it is DELETED
```

To test the whitelist, restore `test.txt` via `restore.sh` (option 1), then
touch the file again — the daemon will not flag it anymore.

## Cleaning Up

Remove generated snapshot files:

```bash
make clean
```
