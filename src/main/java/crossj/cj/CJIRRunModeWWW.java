package crossj.cj;

import crossj.base.FS;
import crossj.json.JSON;

public final class CJIRRunModeWWW extends CJIRRunMode {
    private final String appdir;
    private final JSON config;

    @Override
    public <R, A> R accept(CJIRRunModeVisitor<R, A> visitor, A a) {
        return visitor.visitWWW(this, a);
    }

    public CJIRRunModeWWW(String appdir, JSON config) {
        this.appdir = appdir;
        this.config = config;
    }

    public JSON getConfig() {
        return config;
    }

    public String getMainClass() {
        return config.get("main").getString();
    }

    public String getWwwdir() {
        return FS.join(appdir, "www");
    }

    public String getAppdir() {
        return appdir;
    }
}
