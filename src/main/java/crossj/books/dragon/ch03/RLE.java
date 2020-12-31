package crossj.books.dragon.ch03;

import crossj.base.Assert;

/**
 * Quick and dirty run length encoder/decoder for serializing DFAs.
 *
 * Basically data appears as-is unless a value appears 3 or more times in a row.
 * When that happens, the value is encoded as (ESCAPE, REPTITION, VALUE).
 *
 * This is ok for two reasons:
 *   - the raw encoding of the DFA does not use any negative numbers except -1, and
 *   - there's a loooot of repetition of single values.
 */
final class RLE {
    /**
     * special value to indicate that a run length encoded value will appear.
     */
    private static final int ESCAPE = -8;

    public static int[] encode(int[] arr) {
        // compute how much space is needed
        int size = 0;
        for (int i = 0; i < arr.length;) {
            int j = i + 1;
            while (j < arr.length && arr[i] == arr[j]) {
                j++;
            }
            int len = j - i;
            if (len <= 3) {
                size += len;
            } else {
                size += 3;
            }
            i = j;
        }

        // generate the compressed data
        var ret = new int[size];
        int p = 0;
        for (int i = 0; i < arr.length;) {
            int j = i + 1;
            while (j < arr.length && arr[i] == arr[j]) {
                j++;
            }
            int len = j - i;
            if (len <= 3) {
                for (int k = 0; k < len; k++) {
                    ret[p++] = arr[i];
                }
            } else {
                ret[p++] = ESCAPE;
                ret[p++] = len;
                ret[p++] = arr[i];
            }
            i = j;
        }
        Assert.equals(p, ret.length);
        return ret;
    }

    public static int[] decode(int[] arr) {
        // compute how much space is needed
        int size = 0;
        for (int i = 0; i < arr.length;) {
            if (arr[i] == ESCAPE) {
                i++; // skip the escape
                size += arr[i++]; // get the repeat count
                i++;  // skip the actual value for now
            } else {
                size++;
                i++;
            }
        }

        // generate the decompressed data
        var ret = new int[size];
        int p = 0;
        for (int i = 0; i < arr.length;) {
            if (arr[i] == ESCAPE) {
                i++; // skip the escape
                int rep = arr[i++];
                int value = arr[i++];
                while (rep > 0) {
                    ret[p++] = value;
                    rep--;
                }
            } else {
                ret[p++] = arr[i++];
            }
        }
        Assert.equals(p, size);
        return ret;
    }
}
