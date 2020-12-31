package crossj.base;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.Scanner;

public final class IO {
    private IO() {}
    public static void println(Object object) {
        System.out.println(object.toString());
    }
    public static void eprintln(Object object) {
        System.err.println(object.toString());
    }
    public static void print(Object object) {
        System.out.print(object.toString());
    }
    public static void eprint(Object object) {
        System.err.print(object.toString());
    }
    public static String join(String... parts) {
        return String.join(File.separator, parts);
    }
    public static String separator() {
        return File.separator;
    }
    public static String pathSeparator() {
        return File.pathSeparator;
    }
    public static void writeFile(String filepath, String data) {
        writeFileByteArray(filepath, data.getBytes(StandardCharsets.UTF_8));
    }
    public static void writeFileBytes(String filepath, Bytes data) {
        writeFileByteArray(filepath, data.getByteArray());
    }
    private static void writeFileByteArray(String filepath, byte[] data) {
        try {
            File file = new File(filepath);
            File parent = new File(file.getAbsolutePath()).getParentFile();
            parent.mkdirs();
            Files.write(file.toPath(), data, StandardOpenOption.CREATE,
                    StandardOpenOption.TRUNCATE_EXISTING);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
    public static String readFile(String filepath) {
        return new String(readFileByteArray(filepath), StandardCharsets.UTF_8);
    }
    public static Bytes readFileBytes(String filepath) {
        return Bytes.wrapByteArray(readFileByteArray(filepath));
    }
    private static byte[] readFileByteArray(String filepath) {
        try {
            return Files.readAllBytes(Paths.get(filepath));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
    public static String readResource(String path) {
        InputStream inputStream = IO.class.getClassLoader().getResourceAsStream(path);
        try (Scanner s = new Scanner(inputStream).useDelimiter("\\A")) {
            return s.hasNext() ? s.next() : "";
        }
    }

    /**
     * Read everything in STDIN and return it as a string.
     */
    public static String readStdin() {
        return new String(readStdinByteArray(), StandardCharsets.UTF_8);
    }

    /**
     * Read everything in STDIN and return it as Bytes.
     */
    public static Bytes readStdinBytes() {
        return Bytes.wrapByteArray(readStdinByteArray());
    }

    private static byte[] readStdinByteArray() {
        try {
            return System.in.readAllBytes();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
