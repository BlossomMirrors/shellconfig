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

%post
REAL_USER="\${SUDO_USER:-\$USER}"
USER_HOME=\$(getent passwd "\$REAL_USER" | cut -d: -f6)

fc-cache -f 2>/dev/null || true

# oh-my-zsh
if [ ! -d "\$USER_HOME/.oh-my-zsh" ]; then
    sudo -u "\$REAL_USER" env RUNZSH=no CHSH=no sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>/dev/null || true
fi

# virtualenvwrapper
sudo -u "\$REAL_USER" pip install --user virtualenvwrapper 2>/dev/null || \
sudo -u "\$REAL_USER" pip3 install --user virtualenvwrapper 2>/dev/null || true

# zsh-autosuggestions symlink
CUSTOM="\$USER_HOME/.oh-my-zsh/custom"
mkdir -p "\$CUSTOM/plugins"
ln -sfn /usr/share/zsh/plugins/zsh-autosuggestions "\$CUSTOM/plugins/zsh-autosuggestions"

# user configs
mkdir -p "\$USER_HOME/.config" "\$USER_HOME/.local/share/konsole" "\$USER_HOME/.config/fastfetch"
cp /usr/share/blossomos/shellconfig/zshrc               "\$USER_HOME/.zshrc"
cp /usr/share/blossomos/shellconfig/bashrc              "\$USER_HOME/.bashrc"
cp /usr/share/blossomos/shellconfig/konsolerc           "\$USER_HOME/.config/konsolerc"
cp /usr/share/blossomos/shellconfig/BlossomOS.profile   "\$USER_HOME/.local/share/konsole/BlossomOS.profile"
cp /usr/share/blossomos/shellconfig/fastfetch/config.jsonc       "\$USER_HOME/.config/fastfetch/config.jsonc"
cp /usr/share/blossomos/shellconfig/fastfetch/config-ascii.jsonc "\$USER_HOME/.config/fastfetch/config-ascii.jsonc"
cp /usr/share/blossomos/shellconfig/fastfetch/blossom.txt        "\$USER_HOME/.config/fastfetch/blossom.txt"
cp /usr/share/blossomos/shellconfig/fastfetch/blossom.png        "\$USER_HOME/.config/fastfetch/blossom.png"
chown -R "\$REAL_USER:" "\$USER_HOME/.config/fastfetch" \
    "\$USER_HOME/.zshrc" "\$USER_HOME/.bashrc" \
    "\$USER_HOME/.config/konsolerc" \
    "\$USER_HOME/.local/share/konsole/BlossomOS.profile"

%files
/usr/share/blossomos/shellconfig/
/usr/share/zsh/plugins/zsh-autosuggestions/
/usr/share/fonts/maplemono-nf/
/etc/sudoers.d/blossomos

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
