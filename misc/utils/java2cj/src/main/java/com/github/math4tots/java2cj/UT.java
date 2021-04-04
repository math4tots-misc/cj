package com.github.math4tots.java2cj;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;

/**
 * Utils
 */
public final class UT {
    public static String join(String sep, Iterable<String> parts) {
        var ret = new StringBuilder();
        var first = true;
        for (var part : parts) {
            if (!first) {
                ret.append(sep);
            }
            first = false;
            ret.append(part);
        }
        return ret.toString();
    }

    public static <T, R> List<R> map(Iterable<T> iter, Function<T, R> f) {
        var ret = new ArrayList<R>();
        for (var t : iter) {
            ret.add(f.apply(t));
        }
        return ret;
    }

    public static <R> List<R> cast(Class<R> cls, Iterable<?> iter) {
        var ret = new ArrayList<R>();
        for (var t : iter) {
            if (t == null) {
                throw new NullPointerException();
            }
            ret.add(cls.cast(t));
        }
        return ret;
    }
}
