__CONTAINER=$(/usr/bin/buildah from --name "${NAME}" "${FROM}")
CONFIG()
{
    printf '[\e[1;33m%s\e[m] \e[1;35m%s\e[m\n' "+H" "Applying buildah configuration..."
    /usr/bin/buildah config "$@" "${__CONTAINER}"
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
