package crossj.base;

final class LinkedListIteratorHelper<T> {
    private LinkedListNode<T> node;

    LinkedListIteratorHelper(LinkedListNode<T> node) {
        this.node = node;
    }

    public boolean hasNext() {
        return node != null;
    }

    public T next() {
        T value = node.getHead();
        node = node.getTail();
        return value;
    }
}
