package crossj.base;

/**
 * Interface for resources that may need to be released manually.
 */
public interface Disposable {
    /**
     * Release all resources of this object.
     */
    void dispose();
}
