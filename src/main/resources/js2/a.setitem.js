function setitem(arr, i, x) {
    if (i < 0) {
        i += arr.length;
    }
    if (i < 0 || i >= arr.length) {
        throw new Error(`Index out of bounds (i = ${i}, len = ${arr.length})`);
    }
    arr[i] = x;
}
