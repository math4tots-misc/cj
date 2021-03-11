/**
 * Returns number as is, unless it's NaN, in which case it returns null
 * @param {number} x
 */
 function nanToNull(x) {
    return isNaN(x) ? null : x;
}
