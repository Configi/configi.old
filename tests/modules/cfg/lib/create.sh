PRINT "+H" "Copying artifacts to dummy container image..."
build=$(buildah mount "$NAME")
dummy=$(buildah mount "$SCRATCH")
cp "$build/configi/bin/cfg" "$MANIFEST" "$dummy"
mkdir "$dummy/modules"
if [ -d "$MODULES" ]
then
    cp -R "$MODULES"/. "$dummy/modules"
else
    cp -R $(dirname "$MANIFEST")/modules/. "$dummy/modules"
fi
PRINT "+H" "Removing build container..."
buildah rm "$NAME"
if [ "$ARG" = "local" ]
then
    PRINT "+H" "Committing to containers-storage..."
    buildah commit --rm --squash "$SCRATCH" "containers-storage:configi"
else
    PRINT "+H" "Committing to containers-storage as $ARG..."
    buildah commit --rm --squash "$SCRATCH" "containers-storage:$ARG"
fi
