package crossj.base;

/**
 * File System operations
 */
public final class FS {
    private FS() {}

    private static final String SEPARATOR = FSImpl.getSeparator();

    public static String getSeparator() {
        return SEPARATOR;
    }

    public static String getWorkingDirectory() {
        return FSImpl.getWorkingDirectory();
    }

    public static String join(String... paths) {
        return FSImpl.joinPaths(List.fromJavaArray(paths));
    }

    public static String joinList(List<String> paths) {
        return FSImpl.joinPaths(paths);
    }

    public static boolean isFile(String path) {
        return FSImpl.isFile(path);
    }

    public static boolean isDir(String path) {
        return FSImpl.isDir(path);
    }

    public static List<String> list(String dirpath) {
        return FSImpl.listdir(dirpath);
    }

    /**
     * Recursively walks the directory and lists all found files.
     */
    public static List<String> files(String dirpath) {
        var ret = List.<String>of();
        var stack = List.of(dirpath);
        while (stack.size() > 0) {
            var path = stack.pop();
            for (var item : list(path)) {
                var newPath = join(path, item);
                if (isFile(newPath)) {
                    ret.add(newPath);
                } else if (isDir(newPath)) {
                    stack.add(newPath);
                }
            }
        }
        return ret;
    }
}
