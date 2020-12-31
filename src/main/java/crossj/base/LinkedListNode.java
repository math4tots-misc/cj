package crossj.base;

/**
 * Basic immutable singly linked list with size information.
 *
 * In general, LinkedListNodes are almost always nullable, since
 * an empty LinkedListNode is represented by null.
 */
public final class LinkedListNode<T> {
    public static <T> int sizeOf(LinkedListNode<T> node) {
        return node == null ? 0 : node.len;
    }

    public static <T> LinkedListNode<T> of(T value, LinkedListNode<T> node) {
        return new LinkedListNode<T>(value, node);
    }

    private final T head;
    private final LinkedListNode<T> tail;
    private final int len;

    private LinkedListNode(T head, LinkedListNode<T> tail) {
        this.head = head;
        this.tail = tail;
        this.len = tail == null ? 1 : 1 + tail.len;
    }

    public T getHead() {
        return head;
    }

    public LinkedListNode<T> getTail() {
        return tail;
    }
}
