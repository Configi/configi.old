[ -x "$(command -v buildah)" ] || { echo >&2 "Buildah executable not found."; exit 1; }
[ -x "$(command -v podman)" ] || { echo >&2 "Podman executable not found."; exit 1; }
function CLEANUP {
    printf '[\e[1;33m%s\e[m] \e[1;35m%s\e[m\n' "!!" "Error encountered. Cleaning up..."
    /usr/bin/buildah rm "${NAME}" 2>/dev/null 1>/dev/null
}
trap CLEANUP ERR

printf '[\e[1;33m%s\e[m] \e[1;35m%s\e[m\n' "+H" "Creating ${NAME} container..."
__CONTAINER=$(/usr/bin/buildah from --name "${NAME}" "${FROM}")
CONFIG()
{
    printf '[\e[1;33m%s\e[m] \e[1;35m%s\e[m\n' "+H" "Applying buildah configuration..."
    /usr/bin/buildah config "$@" "${__CONTAINER}"
}

ENTRYPOINT()
{
    printf '[\e[1;33m%s\e[m] \e[1;35m%s\e[m\n' "+H" "Applying entrypoint configuration..."
    /usr/bin/buildah config --entrypoint "$@" "${__CONTAINER}"
    /usr/bin/buildah config --cmd '' "${__CONTAINER}"
    /usr/bin/buildah config --stop-signal TERM "${__CONTAINER}"
}

COMMIT()
{
    printf '[\e[1;33m%s\e[m] \e[1;35m%s\e[m\n' "+H" "Committing container..."
    /usr/bin/buildah commit --rm --squash "${NAME}" "containers-storage:${1}"
}

CLEAR()
{
    printf '[\e[1;33m%s\e[m] \e[1;35m%s\e[m\n' "+C" "Clearing directories..."
    /usr/bin/buildah run ${OPTS} "${__CONTAINER}" \
    /usr/bin/find "$@" -type f -delete || true
    /usr/bin/buildah run ${OPTS} "${__CONTAINER}" \
    /usr/bin/find "$@" -type s -delete || true
    /usr/bin/buildah run ${OPTS} "${__CONTAINER}" \
    /usr/bin/find "$@" -type p -delete || true
    /usr/bin/buildah run ${OPTS} "${__CONTAINER}" \
    /usr/bin/find "$@" -mindepth 1 -type d -delete || true
}
RUN()
{
    printf '[\e[1;33m%s\e[m] \e[1;35m%s\e[m\n' "+C" "Running command..."
    /usr/bin/buildah run ${OPTS} "${__CONTAINER}" -- "$@"
}
COPY()
{
    printf '[\e[1;33m%s\e[m] \e[1;35m%s\e[m\n' "+C" "Copying file..."
    /usr/bin/buildah copy "${__CONTAINER}" "$@"
}
MKDIR()
{
    printf '[\e[1;33m%s\e[m] \e[1;35m%s\e[m\n' "+C" "Creating directory..."
    /usr/bin/buildah run ${OPTS} "${__CONTAINER}" -- mkdir -p "$@"
}
SH()
{
    printf '[\e[1;33m%s\e[m] \e[1;35m%s\e[m\n' "+C" "Spawning shell..."
    /usr/bin/buildah run ${OPTS} "${__CONTAINER}" -- sh -l -c "$@"
}
