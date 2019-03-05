function unit_cleanup() {
    PRINT "+" "Deleting incomplete systemd unit..."
    rm -f "/etc/systemd/system/$SERVICE"
    systemctl daemon-reload
}
trap unit_cleanup ERR

unit_start()
{
    /usr/bin/systemctl daemon-reload
    /usr/bin/systemctl enable "$1"
    /usr/bin/systemctl start "$1"
}

unit_install()
{
    cp "$1" /etc/systemd/system
}

unit_active()
{
    /usr/bin/systemctl is-active "$1" && return 0
    return 1
}

unit_image()
{
    name=$(cut -f1 -d: <<< "${1}")
    tag=$(cut -f2 -d: <<< "${1}")
    [ "$name" = "$tag" ] && tag="latest"
    iid=$(/usr/bin/podman images | grep -F -- "${name} " | grep "$tag" | awk '{print $3}')
    echo "$iid"
    sed -i "s|__IMAGE__|$iid|" "/etc/systemd/system/${2}"
}

unit_stop()
{
    /usr/bin/systemctl stop "$1" 2>&1 >/dev/null || return 0
}
