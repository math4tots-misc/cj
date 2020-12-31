package crossj.base;

import java.util.Arrays;
import java.util.Iterator;

/**
 * For when a List just feels too inefficient, and Bytes is too untyped.
 */
public final class DoubleArray implements XIterable<Double> {
    private final double[] buffer;

    private DoubleArray(double[] buffer) {
        this.buffer = buffer;
    }

    public static DoubleArray of(double... args) {
        return new DoubleArray(args);
    }

    public static DoubleArray fromJavaDoubleArray(double[] args) {
        return of(args);
    }

    /**
     * Returns a zero-filled DoubleArray of the given size
     */
    public static DoubleArray withSize(int size) {
        return new DoubleArray(new double[size]);
    }

    public static DoubleArray fromList(List<Double> list) {
        double[] buffer = new double[list.size()];
        for (int i = 0; i < list.size(); i++) {
            buffer[i] = list.get(i);
        }
        return new DoubleArray(buffer);
    }

    public static DoubleArray fromIterable(XIterable<Double> iterable) {
        if (iterable instanceof DoubleArray) {
            return new DoubleArray(((DoubleArray) iterable).buffer.clone());
        } else {
            return fromList(iterable.iter().list());
        }
    }

    /**
     * Like fromIterable, but if the argument happens to be a DoubleArray already,
     * it will return the value as is instead of creating a copy.
     */
    public static DoubleArray convert(XIterable<Double> iterable) {
        if (iterable instanceof DoubleArray) {
            return (DoubleArray) iterable;
        } else {
            return fromIterable(iterable);
        }
    }

    public int size() {
        return buffer.length;
    }

    public double get(int i) {
        return buffer[i];
    }

    public void set(int i, double value) {
        buffer[i] = value;
    }

    public DoubleArray slice(int start, int end) {
        return new DoubleArray(Arrays.copyOfRange(buffer, start, end));
    }

    public void scale(double factor) {
        for (int i = 0; i < buffer.length; i++) {
            buffer[i] *= factor;
        }
    }

    public void addWithFactor(DoubleArray other, double factor) {
        Assert.equalsWithMessage(buffer.length, other.buffer.length, "DoubleArray.addWithFactor requires arrays of equal size");
        double[] otherBuffer = other.buffer;
        for (int i = 0; i < buffer.length; i++) {
            buffer[i] += otherBuffer[i] * factor;
        }
    }

    @Override
    public XIterator<Double> iter() {
        return XIterator.fromIterator(new Iterator<Double>() {
            int i = 0;

            @Override
            public boolean hasNext() {
                return i < buffer.length;
            }

            @Override
            public Double next() {
                return buffer[i++];
            }
        });
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("DoubleArray.of(");
        for (int i = 0; i < buffer.length; i++) {
            if (i > 0) {
                sb.append(", ");
            }
            sb.append("" + buffer[i]);
        }
        sb.append(")");
        return sb.toString();
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof DoubleArray)) {
            return false;
        }
        DoubleArray arr = (DoubleArray) obj;
        return Arrays.equals(buffer, arr.buffer);
    }

    public DoubleArray clone() {
        return new DoubleArray(buffer.clone());
    }
}
