function cj$JSON$object(pairs) {
    const obj = {};
    for (let i = 0; i < pairs.length; i += 2) {
        obj[pairs[i]] = pairs[i + 1];
    }
    return obj;
}
