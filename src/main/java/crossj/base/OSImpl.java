package crossj.base;

public final class OSImpl {
    static String getEnvOrNull(String key) {
        return System.getenv(key);
    }
}
