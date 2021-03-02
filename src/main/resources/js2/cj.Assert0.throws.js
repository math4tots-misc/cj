function cj$Assert0$throws(f) {
    let thrown = false;
    try { f() } catch (e) { thrown = true; }
    if (!thrown) {
        throw Error("Expected exception to be thrown");
    }
}
