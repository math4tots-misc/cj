package crossj.cj.run;

import crossj.json.JSON;

public final class CJRunModeNW extends CJRunModeWWWBase {
    @Override
    public <R, A> R accept(CJRunModeVisitor<R, A> visitor, A a) {
        return visitor.visitNW(this, a);
    }

    public CJRunModeNW(String appId, String appdir, JSON config) {
        super(appId, appdir, config);
    }
}
