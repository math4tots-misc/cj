package crossj.base;

import java.io.IOException;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Used by FS
 */
public final class FSImpl {
    private FSImpl() {}

    static String getSeparator() {
        return FileSystems.getDefault().getSeparator();
    }

    static String getWorkingDirectory() {
        return System.getProperty("user.dir");
    }

    static String joinPaths(XIterable<String> paths) {
        Path joined = null;
        for (var path: paths) {
            if (joined == null) {
                joined = Paths.get(path);
            } else {
                joined = joined.resolve(path);
            }
        }
        return joined.toString();
    }

    static List<String> listdir(String dirpath) {
        try {
            var list = List.<String>of();
            Files.list(Paths.get(dirpath)).forEach(path -> list.add(path.getFileName().toString()));
            return list;
        } catch (IOException ex) {
            throw XError.withMessage(ex.toString());
        }
    }

    static boolean isFile(String path) {
        return Files.isRegularFile(Paths.get(path));
    }

    static boolean isDir(String path) {
        return Files.isDirectory(Paths.get(path));
    }
}
