_blossom_t() {
    local key="$1"
    local code="${LANG:0:2}"
    local file="/etc/blossomos/guards/${code}.json"
    [[ -f "$file" ]] || file="/etc/blossomos/guards/en.json"
    local val nl=$'\n'
    val=$(grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" 2>/dev/null \
        | sed 's/^"[^"]*"[[:space:]]*:[[:space:]]*"\(.*\)"$/\1/')
    printf '%s' "${val//\\n/${nl}}"
}

rpm-ostree() {
    local _sub="${1:-}"
    local _blocked=0

    case "${_sub}" in
        unlock) _blocked=1 ;;
        usroverlay)
            gum style \
                --border rounded \
                --border-foreground "#FFAA00" \
                --foreground "#FFAA00" \
                --padding "1 2" \
                "$(_blossom_t usroverlay_body)"
            command rpm-ostree "$@"
            return
            ;;
        override)
            case "${2:-}" in
                remove|reset) ;;
                *) _blocked=1 ;;
            esac
            ;;
    esac

    if (( _blocked )); then
        local _title
        _title="$(_blossom_t unlock_title)"
        _title="${_title//\$\{_sub\}/${_sub}}"
        gum style \
            --border double \
            --border-foreground "#FF5555" \
            --foreground "#FF5555" \
            --bold \
            --padding "1 2" \
            "${_title}" \
            "" \
            "$(_blossom_t unlock_body)" \
            "" \
            "$(_blossom_t alternatives)"
        echo
        local _choice
        _choice=$(gum choose \
            "$(_blossom_t opt_brew)" \
            "$(_blossom_t opt_usroverlay)" \
            "$(_blossom_t opt_pkglayer)" \
            "$(_blossom_t opt_ephemeral)" \
            "$(_blossom_t opt_distrobox)" \
            "$(_blossom_t opt_flatpak)" \
            "$(_blossom_t cancel)")
        echo
        case "${_choice}" in
            rpm-ostree*)
                command rpm-ostree usroverlay
                return 0
                ;;
            distrobox*|Distrobox*)
                gum style --foreground "#AAAAFF" \
                    "distrobox create --name mybox --image fedora:latest" \
                    "distrobox enter mybox"
                ;;
            pkglayer*)
                adjust pkglayer
                ;;
            ephemeral*|Einweg*)
                gum style --foreground "#AAAAFF" \
                    "distrobox ephemeral --image fedora:latest -- bash"
                ;;
            flatpak*)
                gum style --foreground "#AAAAFF" \
                    "flatpak install flathub <AppID>" \
                    "flatpak search <name>"
                ;;
            brew*)
                gum style --foreground "#AAAAFF" \
                    "brew install <package>"
                ;;
        esac
        return 1
    fi

    command rpm-ostree "$@"
}
