package crossj.json;

public final class JSNumber extends JSON {
    private final double number;

    JSNumber(double number) {
        this.number = number;
    }

    @Override
    public double getNumber() {
        return number;
    }

    @Override
    public boolean isNumber() {
        return true;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof JSNumber&& ((JSNumber) other).number == number;
    }

    @Override
    public int hashCode() {
        return Double.hashCode(number);
    }

    @Override
    public String toString() {
        return Double.toString(number);
    }
}
