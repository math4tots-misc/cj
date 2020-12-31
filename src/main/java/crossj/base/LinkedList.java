package crossj.base;

/**
 * Basic LinkedList implementation that wraps LinkedListNode.
 */
public final class LinkedList<T> implements XIterable<T> {

    public static <T> LinkedList<T> fromNode(LinkedListNode<T> node) {
        return new LinkedList<>(node);
    }

    public static <T> LinkedList<T> fromLinkedList(LinkedList<T> linkedList) {
        return fromNode(linkedList.node);
    }

    public static <T> LinkedList<T> fromList(List<T> list) {
        LinkedListNode<T> node = null;
        int len = list.size();
        for (int i = len - 1; i >= 0; i--) {
            node = LinkedListNode.of(list.get(i), node);
        }
        return fromNode(node);
    }

    public static <T> LinkedList<T> fromIterable(XIterable<T> iterable) {
        if (iterable instanceof LinkedList<?>) {
            return fromLinkedList((LinkedList<T>) iterable);
        } else if (iterable instanceof List<?>) {
            return fromList((List<T>) iterable);
        } else {
            return fromList(List.fromIterable(iterable));
        }
    }

    @SafeVarargs
    public static <T> LinkedList<T> of(T... values) {
        return fromList(List.fromJavaArray(values));
    }

    private LinkedListNode<T> node;

    private LinkedList(LinkedListNode<T> node) {
        this.node = node;
    }

    public int size() {
        return LinkedListNode.sizeOf(node);
    }

    public boolean isEmpty() {
        return node == null;
    }

    @Override
    public XIterator<T> iter() {
        var helper = new LinkedListIteratorHelper<>(node);
        return XIterator.fromParts(() -> helper.hasNext(), () -> helper.next());
    }
}
