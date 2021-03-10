function cj$Nullable$get(x) {
    if (x === null) {
        throw new Error("Get from empty Nullable");
    }
    return x;
}
