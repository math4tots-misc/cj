package crossj.base;

@SuppressWarnings("serial")
public final class XError extends RuntimeException {
    private XError(String message) {
        super(message);
    }

    public static XError withMessage(String message) {
        return new XError(message);
    }
}
