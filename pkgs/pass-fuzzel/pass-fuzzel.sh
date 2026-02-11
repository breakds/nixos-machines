PASS_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
CLIP_TIMEOUT=45

# --- Step 1: Pick an entry ---
entry=$(
  find "$PASS_DIR" -name '*.gpg' -printf '%P\n' \
    | sed 's/\.gpg$//' \
    | sort \
    | fuzzel --dmenu --prompt "pass> " --lines 15 --width 40
) || exit 0

# --- Step 2: Decrypt once (triggers pinentry for GPG passphrase) ---
decrypted=$(pass show "$entry") || exit 1

# --- Step 3: Parse fields ---
password=$(echo "$decrypted" | head -n1)

# Username is the last component of the entry path
username=$(basename "$entry")

# Check if OTP is available
has_otp=false
if echo "$decrypted" | grep -q 'otpauth://'; then
  has_otp=true
fi

# --- Step 4: Build action menu ---
options="type user"
options="${options}\ntype pass"
if [ "$has_otp" = true ]; then
  options="${options}\ntype otp"
fi
options="${options}\ncopy pass"

action=$(
  printf '%b' "$options" \
    | fuzzel --dmenu --prompt "action> " --lines 5 --width 20
) || exit 0

# --- Step 5: Execute action ---
case "$action" in
  "type user")
    ydotool type -- "$username"
    ;;
  "type pass")
    ydotool type -- "$password"
    ;;
  "type otp")
    ydotool type -- "$(pass otp "$entry")"
    ;;
  "copy pass")
    printf '%s' "$password" | wl-copy
    (
      sleep "$CLIP_TIMEOUT"
      current=$(wl-paste 2>/dev/null || true)
      if [ "$current" = "$password" ]; then
        wl-copy --clear
      fi
    ) &
    disown
    ;;
esac
