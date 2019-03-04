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


