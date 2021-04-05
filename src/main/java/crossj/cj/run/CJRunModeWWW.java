package crossj.cj.run;

import crossj.json.JSON;

public final class CJRunModeWWW extends CJRunModeWWWBase {
    @Override
    public <R, A> R accept(CJRunModeVisitor<R, A> visitor, A a) {
        return visitor.visitWWW(this, a);
    }

    public CJRunModeWWW(String appId, String appdir, JSON config) {
        super(appId, appdir, config);
    }
}
