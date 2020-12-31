package crossj.base;

// Roughly modeled on
// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math
// and also java.lang.Math
public final class M {
    // these constants are really just placeholders,
    // since this is a native class, it should be replaced with actual
    // native values
    public static final double E = Math.E;
    public static final double PI = Math.PI;
    public static final double TAU = PI * 2;
    public static final double INFINITY = Double.POSITIVE_INFINITY;

    public static double max(double value, double... values) {
        for (double x : values) {
            value = Math.max(value, x);
        }
        return value;
    }

    public static int imax(int value, int... values) {
        for (int x : values) {
            value = Math.max(value, x);
        }
        return value;
    }

    public static double min(double value, double... values) {
        for (double x : values) {
            value = Math.min(value, x);
        }
        return value;
    }

    public static int imin(int value, int... values) {
        for (int x : values) {
            value = Math.min(value, x);
        }
        return value;
    }

    public static int cmp(double a, double b) {
        return a < b ? -1 : a == b ? 0 : 1;
    }

    public static int icmp(int a, int b) {
        return a < b ? -1 : a == b ? 0 : 1;
    }

    public static double round(double value) {
        return Math.round(value);
    }

    public static double floor(double value) {
        return Math.floor(value);
    }

    public static double ceil(double value) {
        return Math.ceil(value);
    }

    public static double abs(double value) {
        return Math.abs(value);
    }

    public static int iabs(int x) {
        return Math.abs(x);
    }

    public static double pow(double a, double b) {
        return Math.pow(a, b);
    }

    public static int ipow(int a, int b) {
        return (int) Math.pow(a, b);
    }

    public static double sqrt(double x) {
        return Math.sqrt(x);
    }

    public static double sin(double radians) {
        return Math.sin(radians);
    }

    public static double cos(double radians) {
        return Math.cos(radians);
    }

    public static double tan(double radians) {
        return Math.tan(radians);
    }

    public static double asin(double x) {
        return Math.asin(x);
    }

    public static double acos(double x) {
        return Math.acos(x);
    }

    public static double atan(double x) {
        return Math.atan(x);
    }

    public static double atan2(double y, double x) {
        return Math.atan2(y, x);
    }

    public static double ln(double x) {
        return Math.log(x);
    }

    public static int gcd(int a, int b) {
        while (b != 0) {
            var tmp = b;
            b = a % b;
            a = tmp;
        }
        return a;
    }
}
