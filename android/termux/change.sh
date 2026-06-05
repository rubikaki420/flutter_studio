#!/usr/bin/env bash
set -e

OLD_PKG="com.termux"
NEW_PKG="com.vault.fide"

NEW_UNDERSCORE="$(echo "$NEW_PKG" | tr . _)"
NEW_SLASH="$(echo "$NEW_PKG" | tr . /)"

############################
# Portable sed -i
############################
portable_sed_i() {
    if sed v </dev/null 2>/dev/null; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

############################
# Replace text references
############################
replace_termux_name() {
    local targetdir="$1"
    pushd "$targetdir" >/dev/null

    find . -type f -exec file {} + \
      | grep "text" | cut -d: -f1 | while read -r file; do
        portable_sed_i \
          -e "s|>Vault.Fide<|>Vault.Fide<|g" \
          -e "s|\"Termux\"|\"Vault.Fide\"|g" \
          -e "s|Vault.Fide:|Vault.Fide:|g" \
          -e "s|com\.termux|$NEW_PKG|g" \
          -e "s|com_vault_fide|$NEW_UNDERSCORE|g" \
          -e '/http/!s|com/termux|'"$NEW_SLASH"'|g' \
          "$file"
    done

    popd >/dev/null
}

############################
# Migrate single folder
############################
migrate_termux_folder() {
    local src="$1"
    local parentdir
    parentdir="$(dirname "$(dirname "$src")")"
    local dest="${parentdir}/${NEW_SLASH}"

    if [[ ! -d "$src" ]]; then
        return
    fi

    echo "Migrating:"
    echo "  - $src"
    echo "  + $dest"

    mkdir -p "$dest"
    mv "$src"/* "$dest"/
    rm -rf "$src"
}

############################
# Migrate folder tree
############################
migrate_termux_folder_tree() {
    local targetdir="$1"
    pushd "$targetdir" >/dev/null

    find "$(pwd)" -type d -path "*/com/vault/fide" \
      | grep -v -e 'shared/termux' -e 'settings/termux' \
      | while read -r dir; do
            migrate_termux_folder "$dir"
        done

    popd >/dev/null
}

############################
# RUN
############################
TARGET_DIR="${1:-.}"

echo "[*] Replacing text references..."
replace_termux_name "$TARGET_DIR"

echo "[*] Migrating Java/Kotlin package folders..."
migrate_termux_folder_tree "$TARGET_DIR"

echo "[✓] Done: com.vault.fide → com.vault.fide"