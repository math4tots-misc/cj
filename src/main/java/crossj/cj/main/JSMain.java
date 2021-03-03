package crossj.cj.main;

import crossj.base.FS;
import crossj.base.IO;
import crossj.base.List;
import crossj.cj.CJIRContext;
import crossj.cj.CJIRRunMode;
import crossj.cj.CJIRRunModeMain;
import crossj.cj.CJIRRunModeTest;
import crossj.cj.CJIRRunModeVisitor;
import crossj.cj.CJIRRunModeWWW;
import crossj.cj.CJJSTranslator;
// import crossj.cj.js.CJJSTranslator2;
import crossj.json.JSON;

public final class JSMain {
    public static void main(String[] args) {
        var mode = Mode.Default;
        var sourceRoots = List.of(
            // FS.join("src", "main", "cj2"), // for CJJSTranslator2
            FS.join("src", "main", "cj"));
        var outPath = "";
        String appId = "";
        CJIRRunMode runMode = null;
        for (var arg : args) {
            switch (mode) {
                case Default:
                    switch (arg) {
                        case "-a":
                        case "--app":
                            mode = Mode.App;
                            break;
                        case "-m":
                        case "--main-class":
                            mode = Mode.MainClass;
                            break;
                        case "-r":
                        case "--source-root":
                            mode = Mode.SourceRoot;
                            break;
                        case "-t":
                        case "--test":
                            runMode = new CJIRRunModeTest();
                            sourceRoots.add(FS.join("src", "test", "cj"));
                            break;
                        case "-o":
                        case "--out":
                            mode = Mode.Out;
                            break;
                        default:
                            throw new RuntimeException("Unrecognized arg: " + arg);
                    }
                    break;
                case App:
                    appId = arg;
                    mode = Mode.Default;
                    break;
                case MainClass:
                    runMode = new CJIRRunModeMain(arg);
                    mode = Mode.Default;
                    break;
                case SourceRoot:
                    sourceRoots.add(arg);
                    mode = Mode.Default;
                    break;
                case Out:
                    outPath = arg;
                    mode = Mode.Default;
                    break;
            }
        }
        if (!appId.isEmpty()) {
            runMode = loadAppConfig(sourceRoots, appId);
        }
        if (runMode == null) {
            throw new RuntimeException("--main-class, --app or --test must be specified");
        }
        if (outPath.isEmpty()) {
            throw new RuntimeException("--out path cannot be empty");
        }
        var ctx = new CJIRContext();
        ctx.getSourceRoots().addAll(sourceRoots);
        ctx.loadAutoImportItems();
        var mainClasses = List.<String>of();
        runMode.accept(new CJIRRunModeVisitor<Void,Void>(){

            @Override
            public Void visitMain(CJIRRunModeMain m, Void a) {
                mainClasses.add(m.getMainClass());
                return null;
            }

            @Override
            public Void visitTest(CJIRRunModeTest m, Void a) {
                ctx.loadAllItemsInSourceRoots();
                return null;
            }

            @Override
            public Void visitWWW(CJIRRunModeWWW m, Void a) {
                mainClasses.add(m.getMainClass());
                return null;
            }
        }, null);
        ctx.loadItemsRec(mainClasses);
        ctx.runAllPasses();
        if (runMode instanceof CJIRRunModeMain) {
            var mainClass = ((CJIRRunModeMain) runMode).getMainClass();
            ctx.validateMainItem(ctx.loadItem(mainClass));
        } else if (runMode instanceof CJIRRunModeWWW) {
            var mainClass = ((CJIRRunModeWWW) runMode).getMainClass();
            ctx.validateMainItem(ctx.loadItem(mainClass));
        }

        var jsSink = CJJSTranslator.translate(ctx, runMode);
        if (runMode instanceof CJIRRunModeWWW) {
            var config = ((CJIRRunModeWWW) runMode).getConfig();
            var wwwdir = ((CJIRRunModeWWW) runMode).getWwwdir();
            IO.delete(outPath);
            if (FS.exists(wwwdir)) {
                IO.copyFolder(wwwdir, outPath);
            }
            if (config.has("resources")) {
                var keys = config.get("resources").keys();
                for (var key : keys) {
                    var src = findResourcePath(sourceRoots, key);
                    var reldest = config.get("resources").get(key).getString();
                    var dest = FS.join(outPath, reldest);
                    IO.copy(src, dest);
                }
            }
            var filePath = FS.join(outPath, "main.js");
            var sourceMapPath = filePath + ".map";
            var js = jsSink.getSource(filePath);
            var sourceMap = jsSink.getSourceMap(filePath);
            IO.writeFile(filePath, js);
            IO.writeFile(sourceMapPath, sourceMap);
        } else {
            if (outPath.equals("-")) {
                IO.print(jsSink.getSource(""));
            } else {
                var sourceMapPath = outPath + ".map";
                var js = jsSink.getSource(outPath);
                var sourceMap = jsSink.getSourceMap(outPath);
                IO.writeFile(outPath, js);
                IO.writeFile(sourceMapPath, sourceMap);
            }
        }
    }

    private static enum Mode {
        Default, MainClass, SourceRoot, Out, App,
    }

    private static CJIRRunMode loadAppConfig(List<String> sourceRoots, String appId) {
        var appdir = findAppDir(sourceRoots, appId);
        var config = JSON.parse(IO.readFile(FS.join(appdir, "config.json")));
        var type = config.get("type").getString();
        switch (type) {
            case "www": {
                return new CJIRRunModeWWW(appdir, config);
            }
            default: {
                throw new RuntimeException(appId + " has unsupported app type " + type);
            }
        }
    }

    private static String findAppDir(List<String> sourceRoots, String appId) {
        for (var sourceRoot : sourceRoots) {
            var candidate = FS.join(sourceRoot, "..", "app", appId);
            if (FS.isDir(candidate)) {
                return candidate;
            }
        }
        throw new RuntimeException("App directory for " + appId + " not found");
    }

    private static String findResourcePath(List<String> sourceRoots, String relpath) {
        for (var sourceRoot : sourceRoots) {
            var candidate = FS.join(sourceRoot, "..", "resources", relpath);
            if (FS.exists(candidate)) {
                return candidate;
            }
        }
        throw new RuntimeException("Resource " + relpath + " not found");
    }
}
