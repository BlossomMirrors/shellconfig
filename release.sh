#!/usr/bin/env bash
set -e

NAME=blossomos-shellconfig
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_VERSION=$(cat "$SCRIPT_DIR/VERSION")
BATCH=false
[[ "${1:-}" == "--batch" ]] && BATCH=true

ask() {
    local prompt="$1" default="$2"
    if $BATCH; then echo "$default"; return; fi
    read -rp "$prompt [$default]: " v
    echo "${v:-$default}"
}

VERSION=$(ask "Version" "$CURRENT_VERSION")
RELEASE=$(ask "Release" "1")
CHANGELOG=$(ask "Changelog" "packaged $NAME $VERSION")

if [[ "$VERSION" != "$CURRENT_VERSION" ]]; then
    echo "$VERSION" > "$SCRIPT_DIR/VERSION"
fi

RPMBUILD=~/rpmbuild
mkdir -p "$RPMBUILD"/{SPECS,SOURCES,BUILD,RPMS,SRPMS} "$SCRIPT_DIR/release"

tar -czf "$RPMBUILD/SOURCES/$NAME-$VERSION.tar.gz" \
    --transform "s|^\./|$NAME-$VERSION/|" \
    --exclude=./.git --exclude=./release --exclude=./.claude \
    -C "$SCRIPT_DIR" .

cat > "$RPMBUILD/SPECS/$NAME.spec" << EOF
Name:           $NAME
Version:        $VERSION
Release:        $RELEASE%{?dist}
Summary:        BlossomOS shell configuration and terminal theming
License:        GPL-3.0-or-later
URL:            https://git.blossomos.org/Blossom/shellconfig
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

Requires:       zsh
Requires:       micro
Requires:       fastfetch
Requires:       konsole
Requires:       python3-pip
Requires:       blossomui
Requires:       git
Requires:       curl
Requires:       atuin

%description
Shell configuration, zsh plugins, Konsole profile and color scheme for BlossomOS.

%prep
%autosetup

%install
install -dm 755 %{buildroot}/usr/share/blossomos/shellconfig
install -Dm 644 zshrc       %{buildroot}/usr/share/blossomos/shellconfig/zshrc
install -Dm 644 bashrc      %{buildroot}/usr/share/blossomos/shellconfig/bashrc
install -Dm 644 konsolerc   %{buildroot}/usr/share/blossomos/shellconfig/konsolerc
install -Dm 644 BlossomOS.profile %{buildroot}/usr/share/blossomos/shellconfig/BlossomOS.profile
install -Dm 440 sudoers-blossomos %{buildroot}/etc/sudoers.d/blossomos
install -Dm 644 fastfetch/config.jsonc       %{buildroot}/usr/share/blossomos/shellconfig/fastfetch/config.jsonc
install -Dm 644 fastfetch/config-ascii.jsonc %{buildroot}/usr/share/blossomos/shellconfig/fastfetch/config-ascii.jsonc
install -Dm 644 fastfetch/blossom.txt        %{buildroot}/usr/share/blossomos/shellconfig/fastfetch/blossom.txt
install -Dm 644 fastfetch/blossom.png        %{buildroot}/usr/share/blossomos/shellconfig/fastfetch/blossom.png
install -dm 755 %{buildroot}/usr/share/zsh/plugins
cp -r plugins/zsh-autosuggestions %{buildroot}/usr/share/zsh/plugins/

install -dm 755 %{buildroot}/usr/share/fonts/maplemono-nf
install -Dm 644 maplemono-nf/maplemono-nf-regular.ttf \
    %{buildroot}/usr/share/fonts/maplemono-nf/maplemono-nf-regular.ttf

install -Dm 644 zshrc             %{buildroot}/etc/skel/.zshrc
install -Dm 644 bashrc            %{buildroot}/etc/skel/.bashrc
install -Dm 644 konsolerc         %{buildroot}/etc/skel/.config/konsolerc
install -Dm 644 BlossomOS.profile %{buildroot}/etc/skel/.local/share/konsole/BlossomOS.profile
install -Dm 644 fastfetch/config.jsonc       %{buildroot}/etc/skel/.config/fastfetch/config.jsonc
install -Dm 644 fastfetch/config-ascii.jsonc %{buildroot}/etc/skel/.config/fastfetch/config-ascii.jsonc
install -Dm 644 fastfetch/blossom.txt        %{buildroot}/etc/skel/.config/fastfetch/blossom.txt
install -Dm 644 fastfetch/blossom.png        %{buildroot}/etc/skel/.config/fastfetch/blossom.png

%post
REAL_USER="\${SUDO_USER:-\$USER}"
USER_HOME=\$(getent passwd "\$REAL_USER" | cut -d: -f6)

fc-cache -f 2>/dev/null || true

# Deploy skel files to the installing user's home (in addition to /etc/skel for new users)
if [ -n "\$REAL_USER" ] && [ "\$REAL_USER" != "root" ] && [ -d "\$USER_HOME" ]; then
    install -dm 755 -o "\$REAL_USER" -g "\$REAL_USER" \\
        "\$USER_HOME/.config" \\
        "\$USER_HOME/.config/fastfetch" \\
        "\$USER_HOME/.local/share/konsole"
    for rel in .zshrc .bashrc .config/konsolerc \\
               .local/share/konsole/BlossomOS.profile \\
               .config/fastfetch/config.jsonc \\
               .config/fastfetch/config-ascii.jsonc \\
               .config/fastfetch/blossom.txt \\
               .config/fastfetch/blossom.png; do
        src="/etc/skel/\$rel"
        dst="\$USER_HOME/\$rel"
        if [ -f "\$src" ]; then
            install -Dm 644 -o "\$REAL_USER" -g "\$REAL_USER" "\$src" "\$dst"
        fi
    done
fi

# oh-my-zsh
OMZ_REPO=https://github.com/ohmyzsh/ohmyzsh.git

if [ ! -f /etc/skel/.oh-my-zsh/oh-my-zsh.sh ]; then
    rm -rf /etc/skel/.oh-my-zsh
    git clone --depth=1 "\$OMZ_REPO" /etc/skel/.oh-my-zsh || \\
        echo "WARNING: oh-my-zsh clone into /etc/skel failed"
fi

if [ -n "\$REAL_USER" ] && [ "\$REAL_USER" != "root" ] && \\
   [ ! -f "\$USER_HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    rm -rf "\$USER_HOME/.oh-my-zsh"
    sudo -u "\$REAL_USER" -H git clone --depth=1 \\
        "\$OMZ_REPO" "\$USER_HOME/.oh-my-zsh" || \\
        echo "WARNING: oh-my-zsh clone for \$REAL_USER failed"
fi

# virtualenvwrapper
sudo -u "\$REAL_USER" pip install --user virtualenvwrapper 2>/dev/null || \
sudo -u "\$REAL_USER" pip3 install --user virtualenvwrapper 2>/dev/null || true

# zsh-autosuggestions symlink
if [ -d /etc/skel/.oh-my-zsh ]; then
    mkdir -p /etc/skel/.oh-my-zsh/custom/plugins
    ln -sfn /usr/share/zsh/plugins/zsh-autosuggestions \\
        /etc/skel/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi
if [ -n "\$REAL_USER" ] && [ "\$REAL_USER" != "root" ] && [ -d "\$USER_HOME/.oh-my-zsh" ]; then
    CUSTOM="\$USER_HOME/.oh-my-zsh/custom"
    sudo -u "\$REAL_USER" -H mkdir -p "\$CUSTOM/plugins"
    sudo -u "\$REAL_USER" -H ln -sfn /usr/share/zsh/plugins/zsh-autosuggestions "\$CUSTOM/plugins/zsh-autosuggestions"
fi

%files
/usr/share/blossomos/shellconfig/
/usr/share/zsh/plugins/zsh-autosuggestions/
/usr/share/fonts/maplemono-nf/
/etc/sudoers.d/blossomos
/etc/skel/.zshrc
/etc/skel/.bashrc
/etc/skel/.config/konsolerc
/etc/skel/.local/share/konsole/BlossomOS.profile
/etc/skel/.config/fastfetch/

%changelog
* $(LC_TIME=C date "+%a %b %d %Y") packager - $VERSION-$RELEASE
- $CHANGELOG
EOF

if command -v rpmbuild >/dev/null 2>&1; then
    rpmbuild -ba "$RPMBUILD/SPECS/$NAME.spec"
    find "$RPMBUILD/RPMS" -name "$NAME-$VERSION-$RELEASE*.rpm" -exec cp {} "$SCRIPT_DIR/release/" \;
    echo "Done: $(ls "$SCRIPT_DIR/release/")"
else
    echo "rpmbuild not found, skipping RPM release."
fi
