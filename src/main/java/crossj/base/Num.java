package crossj.base;

/**
 * Some utilities for dealing with doubles
 */
public final class Num {
    private Num() {
    }

    public static boolean areClose(double a, double b) {
        // TODO: do something better
        return M.abs(a - b) < 0.00000000001;
    }

    public static double parseDouble(String s) {
        return Double.parseDouble(s);
    }

    public static int parseInt(String s) {
        return Integer.parseInt(s);
    }

    public static String format(double x) {
        var i = (int) (x * 1000);
        var afterDecimal = Str.lpad("" + (i % 1000), 3, "0");
        var beforeDecimal = "" + (i / 1000);
        while (afterDecimal.endsWith("0")) {
            afterDecimal = afterDecimal.substring(0, afterDecimal.length() - 1);
        }
        if (afterDecimal.length() == 0) {
            return beforeDecimal;
        } else {
            return beforeDecimal + "." + afterDecimal;
        }
    }
}
