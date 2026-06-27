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
            sudo rpm-ostree "$@"
            return
            ;;
        install)
            [[ " $* " == *" --apply-live "* ]] && _blocked=1
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
            "$(_blossom_t opt_unlock_passphrase)" \
            "$(_blossom_t cancel)")
        echo
        case "${_choice}" in
            rpm-ostree*)
                sudo rpm-ostree usroverlay
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
            unlock*)
                if command rpm-ostree status 2>/dev/null | grep -q 'Unlocked:'; then
                    return 0
                fi
                local _passphrase
                local -a _w=(
                    apple beach blade brave bread bright candy chain charm chase
                    clear clock cloud craft dance depth dream drift drive eagle
                    ember faith field fight flame flash float flour flower focus
                    force forge frame fresh frost fruit grace grain grand grass
                    green guard guide happy harsh heart heavy horse house image
                    judge juice knife large laser learn level light logic lucky
                    magic maple march match metal might model mouse music ocean
                    olive panel paper patch peace pearl pilot pixel place plant
                    polar power press price probe proud pulse reach realm rebel
                    reply rider risky river robot rocky royal ruler saint sandy
                    sauce scale scout shade shake shape share shark sharp shelf
                    skill sleep slope smart smoke solar solid solve space spare
                    spark speak speed spike spine sport spray stack stage stain
                    stand stare stark start state steel stone storm story straw
                    study style sugar super surge taste teach tiger toast touch
                    tough tower trace track trade trail train trust truth vapor
                    vault verse vigor viral visit voice water wedge wheel white
                    world worth write yield youth zebra
                )
                local _suffix
                _suffix=$(printf '%s\n' "${_w[@]}" | shuf -n 3 | paste -sd ' ')
                _passphrase="ich weiss wirklich wirklich was ich da tue ${_suffix}"
                echo
                gum style \
                    --border rounded \
                    --border-foreground "#FF5555" \
                    --foreground "#FFAA00" \
                    --bold \
                    --padding "1 2" \
                    "$(_blossom_t passphrase_label)" \
                    "${_passphrase}"
                echo
                local _input
                _input=$(gum input --placeholder "$(_blossom_t passphrase_input_placeholder)")
                if [[ "$_input" == "$_passphrase" ]]; then
                    sudo rpm-ostree "$@"
                    return $?
                else
                    gum style --foreground "#FF5555" "$(_blossom_t passphrase_wrong)"
                fi
                ;;
        esac
        return 1
    fi

    command rpm-ostree "$@"
}
