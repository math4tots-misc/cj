package crossj.base.annotations;

/**
 * Annotation that indicates that the class should use object identity
 * hash and equality semantics.
 *
 * In Java this is the default behavior. But in other languages, this
 * might not be -- this annotation asks that this behavior be upheld
 * for the given class.
 */
public @interface IdHash {
}
