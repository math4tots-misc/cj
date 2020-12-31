package crossj.base;

public final class Try<T> {
    private final T value;
    private final String message;
    private final LinkedListNode<String> context;

    private Try(T value, String message, LinkedListNode<String> context) {
        this.value = value;
        this.message = message;
        this.context = context;
    }

    public static <T> Try<T> ok(T value) {
        return new Try<T>(value, null, null);
    }

    public static <T> Try<T> fail(String message) {
        return failWithContext(message, null);
    }

    public static <T> Try<T> failWithContext(String message, LinkedListNode<String> context) {
        return new Try<T>(null, message, context);
    }

    public boolean isOk() {
        return message == null;
    }

    public boolean isFail() {
        return message != null;
    }

    public T get() {
        if (isFail()) {
            throw XError.withMessage("Get from a failed Try: " + getErrorMessageWithContext());
        }
        return value;
    }

    public T getOrElse(Func0<T> f) {
        return isOk() ? value : f.apply();
    }

    public String getErrorMessage() {
        if (isOk()) {
            throw XError.withMessage("getErrorMessage from an ok Try");
        }
        return message;
    }

    public String getErrorMessageWithContext() {
        if (isOk()) {
            throw XError.withMessage("getErrorMessageWithContext from an ok Try");
        }
        var sb = Str.builder();
        sb.s("Context (most recent entry last):\n");
        for (var entry : LinkedList.fromNode(context)) {
            sb.s("  ").s(entry).s("\n");
        }
        sb.s("ERROR: ").s(message).s("\n");
        return sb.build();
    }

    /**
     * Returns a LinkedList of all the contexts added to this
     * Try, if this is a failed Try.
     *
     * If this Try is ok, throws an exception
     */
    public LinkedList<String> getErrorContext() {
        if (isOk()) {
            throw XError.withMessage("getErrorContext from an ok Try");
        }
        return LinkedList.fromNode(context);
    }

    public <R> Try<R> map(Func1<R, T> f) {
        return isOk() ? ok(f.apply(value)) : failWithContext(message, context);
    }

    public <R> Try<R> flatMap(Func1<Try<R>, T> f) {
        return isOk() ? f.apply(value) : failWithContext(message, context);
    }

    /**
     * If this is ok, returns this.
     * Otherwise, returns the failure with the additional context added.
     */
    public Try<T> withContext(String additionalContext) {
        return isOk() ? this : failWithContext(message, LinkedListNode.of(additionalContext, context));
    }

    /**
     * Asserts that this Try instance is a fail, and returns this instance as a Try
     * of any desired type
     */
    public <R> Try<R> castFail() {
        if (isOk()) {
            throw XError.withMessage("Expected fail, but got ok");
        }
        return failWithContext(message, context);
    }
}
