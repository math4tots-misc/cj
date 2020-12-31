package crossj.base;

public final class OS {
    public static String getenv(String key) {
        var value = OSImpl.getEnvOrNull(key);
        if (value == null) {
            throw XError.withMessage("Environment variable " + key + " not found");
        }
        return value;
    }

    public static String getenvOrEmpty(String key) {
        return Optional.of(OSImpl.getEnvOrNull(key)).getOrElse("");
    }

    public static String getenvOrNull(String key) {
        return OSImpl.getEnvOrNull(key);
    }
}
