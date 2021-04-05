package crossj.cj.run;

import crossj.json.JSON;

public abstract class CJRunModeWWWBase extends CJRunMode {
    private final String appId;
    private final String appdir;
    private final JSON config;

    public CJRunModeWWWBase(String appId, String appdir, JSON config) {
        this.appId = appId;
        this.appdir = appdir;
        this.config = config;
    }

    public String getAppId() {
        return appId;
    }

    public JSON getConfig() {
        return config;
    }

    public String getMainClass() {
        return config.get("main").getString();
    }

    public String getAppdir() {
        return appdir;
    }
}
