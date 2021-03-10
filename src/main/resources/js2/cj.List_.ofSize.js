function cj$List_$ofSize(n, f) {
    const ret = [];
    for (let i = 0; i < n; i++) {
        ret.push(f(i));
    }
    return ret;
}
