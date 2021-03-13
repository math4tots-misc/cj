package crossj.cj;

import crossj.json.JSON;

public final class CJIRRunModeNW extends CJIRRunModeWWWBase {
    @Override
    public <R, A> R accept(CJIRRunModeVisitor<R, A> visitor, A a) {
        return visitor.visitNW(this, a);
    }

    public CJIRRunModeNW(String appId, String appdir, JSON config) {
        super(appId, appdir, config);
    }
}
