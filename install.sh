#!/usr/bin/env bash
# Standalone installer. Compatible with macOS Bash 3.2; chezmoi is bootstrapped if missing.
set -euo pipefail
umask 077

repo_url=${DOTFILES_REPO:-https://github.com/dirichy/chezmoi.git}
source_dir=""
yes=0
reinit=0
plugins=1
services=1
hooks=1
identity=1
store_url=""
cm_options=()

usage() {
    cat <<'USAGE'
Usage: bash install.sh [options]
  --repo URL          Repository to initialize when no checkout exists
  --source DIR        Use an existing checkout or initialize into DIR
  --proxy URL         Temporary HTTP proxy (or set BOOTSTRAP_PROXY)
  --init              Regenerate config, reusing saved answers and asking new questions
  --yes               Accept installation prompts; also accept service changes
  --skip-plugins      Skip application/plugin initialization
  --skip-services     Skip package service setup and user service reconciliation
  --skip-hooks        Skip repository Git hook configuration
  --skip-identity     Skip device keys and password-store enrollment
  --store URL         Existing gopass Git repository (or DOTFILES_GOPASS_REPO)
  --config PATH       Use a specific chezmoi config
  --destination DIR   Use a specific chezmoi destination
  --cache DIR         Use a specific chezmoi cache
  --state PATH        Use a specific chezmoi persistent state
USAGE
}

while (($#)); do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --yes) yes=1; shift ;;
        --init) reinit=1; shift ;;
        --skip-plugins) plugins=0; shift ;;
        --skip-services) services=0; shift ;;
        --skip-hooks) hooks=0; shift ;;
        --skip-identity) identity=0; shift ;;
        --repo|--source|--proxy|--store|--config|--destination|--cache|--state)
            (($# >= 2)) || { printf 'Missing value for %s\n' "$1" >&2; exit 2; }
            case "$1" in
                --repo) repo_url=$2 ;;
                --source) source_dir=$2 ;;
                --proxy) BOOTSTRAP_PROXY=$2 ;;
                --store) store_url=$2 ;;
                --state) cm_options+=(--persistent-state "$2") ;;
                *) cm_options+=("$1" "$2") ;;
            esac
            shift 2 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

case $(uname -s) in
    Linux|Darwin) ;;
    *) printf 'Only Linux and macOS are supported.\n' >&2; exit 1 ;;
esac
if [[ $services == 0 ]]; then export SKIP_SERVICES=1 DOTFILES_SKIP_SERVICES=1; fi
if [[ $plugins == 0 ]]; then export DOTFILES_SKIP_APP_INIT=1; fi
if [[ $hooks == 0 ]]; then export DOTFILES_SKIP_HOOKS=1; fi
if [[ $yes == 1 ]]; then export DOTFILES_SERVICES_YES=1; fi

confirm() {
    local answer
    [[ $yes == 1 ]] && return 0
    [[ -t 0 ]] || { printf '%s: use --yes in noninteractive mode.\n' "$1" >&2; return 1; }
    read -r -p "$1 [Y/n] " answer
    [[ -z $answer || $answer == y || $answer == Y || $answer == yes ]]
}

if [[ -z ${BOOTSTRAP_PROXY:-} && $yes == 0 && -t 0 ]]; then
    read -r -p 'Temporary HTTP proxy URL (empty: keep current network environment): ' BOOTSTRAP_PROXY
fi
if [[ -n ${BOOTSTRAP_PROXY:-} ]]; then
    case "$BOOTSTRAP_PROXY" in
        http://?*|https://?*) ;;
        *) printf 'Temporary proxy must be an http:// or https:// URL.\n' >&2; exit 2 ;;
    esac
    [[ $BOOTSTRAP_PROXY != *[[:space:]]* ]] || { printf 'Proxy URL must not contain whitespace.\n' >&2; exit 2; }
    export BOOTSTRAP_PROXY
    export http_proxy="$BOOTSTRAP_PROXY" https_proxy="$BOOTSTRAP_PROXY" all_proxy="$BOOTSTRAP_PROXY"
    export HTTP_PROXY="$BOOTSTRAP_PROXY" HTTPS_PROXY="$BOOTSTRAP_PROXY" ALL_PROXY="$BOOTSTRAP_PROXY"
    export no_proxy="${BOOTSTRAP_NO_PROXY:-localhost,127.0.0.1,::1}" NO_PROXY="${BOOTSTRAP_NO_PROXY:-localhost,127.0.0.1,::1}"
    # Override Git proxy settings for child processes without changing gitconfig.
    git_config_count=${GIT_CONFIG_COUNT:-0}
    [[ $git_config_count != *[!0-9]* && -n $git_config_count ]] || exit 2
    export "GIT_CONFIG_KEY_$git_config_count=http.proxy"
    export "GIT_CONFIG_VALUE_$git_config_count=$BOOTSTRAP_PROXY"
    export GIT_CONFIG_COUNT=$((git_config_count + 1))
    printf 'Temporary installation proxy enabled for this process tree.\n'
fi

work=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX")
trap 'rm -rf "$work"' EXIT
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

# Repository initialization needs Git before profile-specific installation is available.
if ! command -v git >/dev/null 2>&1; then
    if command -v pacman >/dev/null 2>&1; then
        confirm 'Install Git using sudo pacman before initializing the repository?' || exit 1
        if [[ -n ${BOOTSTRAP_PROXY:-} ]]; then
            sudo --preserve-env=http_proxy,https_proxy,all_proxy,HTTP_PROXY,HTTPS_PROXY,ALL_PROXY,no_proxy,NO_PROXY \
                pacman -S --needed --noconfirm git
        else
            sudo pacman -S --needed --noconfirm git
        fi
    else
        printf 'Git is required before repository initialization; install it, then retry.\n' >&2
        exit 1
    fi
fi

if ! command -v chezmoi >/dev/null 2>&1; then
    confirm 'Install chezmoi into ~/.local/bin?' || exit 1
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL https://get.chezmoi.io -o "$work/get-chezmoi.sh"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$work/get-chezmoi.sh" https://get.chezmoi.io
    else
        printf 'curl or wget is required to bootstrap chezmoi. Install one, then retry.\n' >&2
        exit 1
    fi
    sh -n "$work/get-chezmoi.sh"
    sh "$work/get-chezmoi.sh" -b "$HOME/.local/bin"
    command -v chezmoi >/dev/null 2>&1 || { printf 'chezmoi installation failed.\n' >&2; exit 1; }
else
    printf 'chezmoi is already installed; skipping bootstrap.\n'
fi

if [[ -z $source_dir ]]; then
    script_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]:-./install.sh}")" && pwd)
    if [[ -f "$script_dir/.chezmoi.toml.tmpl" ]]; then
        source_dir=$script_dir
    else
        source_dir=$(chezmoi ${cm_options[@]+"${cm_options[@]}"} source-path)
    fi
fi
cm=(chezmoi --source "$source_dir" ${cm_options[@]+"${cm_options[@]}"})
configured=$("${cm[@]}" execute-template '{{ and (hasKey . "install") (hasKey . "features") }}' 2>/dev/null || true)
if [[ ! -f "$source_dir/.chezmoi.toml.tmpl" ]]; then
    [[ ! -e $source_dir/.git ]] || { printf 'Selected checkout is not this dotfiles source; refusing to overwrite it.\n' >&2; exit 1; }
    "${cm[@]}" init "$repo_url"
elif [[ $reinit == 1 || $configured != true ]]; then
    "${cm[@]}" init
else
    printf 'Existing checkout and init answers found; reusing them.\n'
fi
source_dir=$(CDPATH='' cd -- "$source_dir" && pwd)

failures=()
failure_count=0
step() {
    local label=$1
    shift
    printf '\n==> %s\n' "$label"
    if "$@"; then
        return 0
    else
        failures+=("$label")
        failure_count=$((failure_count + 1))
        printf 'Warning: %s failed; continuing independent steps.\n' "$label" >&2
    fi
}

install_packages() {
    bash "$source_dir/ignore/bin/dotfiles-packages" ${cm_options[@]+"${cm_options[@]}"}
}

setup_identity() {
    local destination name email profile
    profile=$("${cm[@]}" execute-template '{{ .install.profile }}') || return
    [[ $profile != skip ]] || return 0
    destination=$("${cm[@]}" execute-template '{{ .chezmoi.destDir }}') || return
    name=$("${cm[@]}" execute-template '{{ .name }}') || return
    email=$("${cm[@]}" execute-template '{{ .email }}') || return
    local args=(--name "$name" --email "$email")
    [[ -z $store_url ]] || args+=(--store "$store_url")
    [[ $yes == 0 ]] || args+=(--yes)
    HOME="$destination" XDG_CONFIG_HOME="$destination/.config" XDG_DATA_HOME="$destination/.local/share" \
        XDG_CACHE_HOME="$destination/.cache" GNUPGHOME="$destination/.gnupg" \
        bash "$source_dir/ignore/bin/dotfiles-identity" "${args[@]}"
}

install_dependencies=0
if confirm 'Install missing packages for the configured profile/modules?'; then
    install_dependencies=1
    # Identity enrollment requires SSH/GPG/gopass before optional applications.
    step 'Install core dependencies' env INSTALL_MODULES=core bash "$source_dir/ignore/bin/dotfiles-packages" ${cm_options[@]+"${cm_options[@]}"}
fi
if [[ $identity == 1 ]]; then
    step 'Prepare device keys and password store' setup_identity
fi
if [[ $install_dependencies == 1 ]]; then
    step 'Install missing dependencies' install_packages
fi
# Normal apply owns all repeatable maintenance, including future run_* additions.
step 'Apply configuration and maintenance' "${cm[@]}" apply --keep-going

if ((failure_count)); then
    printf '\nInstallation finished with failures:\n' >&2
    printf '  - %s\n' "${failures[@]}" >&2
    printf 'Use chezmoi x packages for dependencies, chezmoi x identity for device enrollment, then chezmoi apply --keep-going.\n' >&2
    exit 1
fi
printf '\nInstallation completed. Desktop permissions and account logins still require manual setup.\n'
if [[ -n ${BOOTSTRAP_PROXY:-} ]]; then
    printf 'The temporary proxy was not saved. Verify local Mihomo before opening a normal shell with the daily proxy settings.\n'
fi
