package crossj.base;

import java.math.BigInteger;

/**
 * Normalizing wrapper around Java's BigInteger
 */
public final class BigInt implements TypedEq<BigInt> {
    private static final BigInt ONE = new BigInt(BigInteger.ONE);
    private static final BigInt ZERO = new BigInt(BigInteger.ZERO);

    private final BigInteger value;

    private BigInt(BigInteger value) {
        this.value = value;
    }

    public static BigInt one() {
        return ONE;
    }

    public static BigInt zero() {
        return ZERO;
    }

    public static BigInt fromInt(int value) {
        return new BigInt(BigInteger.valueOf(value));
    }

    public static BigInt fromDouble(double value) {
        return new BigInt(BigInteger.valueOf((long) value));
    }

    public static BigInt fromString(String string) {
        return new BigInt(new BigInteger(string));
    }

    public static BigInt fromHexString(String string) {
        return new BigInt(new BigInteger(string, 16));
    }

    public static BigInt fromOctString(String string) {
        return new BigInt(new BigInteger(string, 8));
    }

    public int intValue() {
        return value.intValue();
    }

    public double doubleValue() {
        return value.doubleValue();
    }

    public BigInt abs() {
        return new BigInt(value.abs());
    }

    public BigInt negate() {
        return new BigInt(value.negate());
    }

    public BigInt add(BigInt other) {
        return new BigInt(value.add(other.value));
    }

    public BigInt subtract(BigInt other) {
        return new BigInt(value.subtract(other.value));
    }

    public BigInt multiply(BigInt other) {
        return new BigInt(value.multiply(other.value));
    }

    public BigInt divide(BigInt other) {
        return new BigInt(value.divide(other.value));
    }

    public BigInt remainder(BigInt other) {
        return new BigInt(value.remainder(other.value));
    }

    public BigInt pow(int other) {
        return new BigInt(value.pow(other));
    }

    public BigInt gcd(BigInt other) {
        return new BigInt(value.gcd(other.value));
    }

    @Override
    public boolean equals(Object obj) {
        return rawEquals(obj);
    }

    @Override
    public boolean isEqualTo(BigInt other) {
        return value.equals(other.value);
    }

    @Override
    public int hashCode() {
        return value.hashCode();
    }

    @Override
    public String toString() {
        return "" + value;
    }
}
