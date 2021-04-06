package crossj.cj.main;

import crossj.base.FS;
import crossj.base.IO;
import crossj.base.List;
import crossj.cj.CJContext;
import crossj.cj.js.CJJSTranslator;
import crossj.cj.js2.CJJSTranslator2;
import crossj.cj.run.CJRunMode;
import crossj.cj.run.CJRunModeMain;
import crossj.cj.run.CJRunModeNW;
import crossj.cj.run.CJRunModeTest;
import crossj.cj.run.CJRunModeVisitor;
import crossj.cj.run.CJRunModeWWW;
import crossj.cj.run.CJRunModeWWWBase;
import crossj.json.JSON;

public final class JSMain {
    public static void main(String[] args) {
        var mode = Mode.Default;
        var sourceRoots = List.<String>of();
        var outPath = "";
        String appId = "";
        CJRunMode runMode = null;
        boolean useTranslator2 = false;
        String cjHome = System.getenv("CJ_HOME");
        if (cjHome == null) {
            cjHome = ".";
        }
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
                case "-tr2":
                case "--use-translator2":
                    useTranslator2 = true;
                    break;
                case "-t":
                case "--test":
                    runMode = new CJRunModeTest(false);
                    sourceRoots.add(FS.join(cjHome, "src", "test", "cj"));
                    sourceRoots.add(FS.join(cjHome, "..", "cjx", "src", "test", "cj"));
                    break;
                case "--all-tests":
                    runMode = new CJRunModeTest(true);
                    sourceRoots.add(FS.join(cjHome, "src", "test", "cj"));
                    sourceRoots.add(FS.join(cjHome, "..", "cjx", "src", "test", "cj"));
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
                runMode = new CJRunModeMain(arg);
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
        sourceRoots.add(FS.join(cjHome, "src", "main", "cj"));

        // cjx is the private repository containing non-open source CJ code.
        sourceRoots.add(FS.join(cjHome, "..", "cjx", "src", "main", "cj"));

        if (!appId.isEmpty()) {
            runMode = loadAppConfig(sourceRoots, appId);
        }
        if (runMode == null) {
            throw new RuntimeException("--main-class, --app or --test must be specified");
        }
        if (outPath.isEmpty()) {
            throw new RuntimeException("--out path cannot be empty");
        }
        var ctx = new CJContext();
        ctx.getSourceRoots().addAll(sourceRoots);
        ctx.loadAutoImportItems();
        var mainClasses = List.<String>of();
        runMode.accept(new CJRunModeVisitor<Void, Void>() {

            @Override
            public Void visitMain(CJRunModeMain m, Void a) {
                mainClasses.add(m.getMainClass());
                return null;
            }

            @Override
            public Void visitTest(CJRunModeTest m, Void a) {
                ctx.loadAllItemsInSourceRoots();
                return null;
            }

            @Override
            public Void visitWWW(CJRunModeWWW m, Void a) {
                mainClasses.add(m.getMainClass());
                return null;
            }

            @Override
            public Void visitNW(CJRunModeNW m, Void a) {
                mainClasses.add(m.getMainClass());
                return null;
            }
        }, null);
        ctx.loadItemsRec(mainClasses);
        ctx.runAllPasses();
        if (runMode instanceof CJRunModeMain) {
            var mainClass = ((CJRunModeMain) runMode).getMainClass();
            ctx.validateMainItem(ctx.loadItem(mainClass));
        } else if (runMode instanceof CJRunModeWWW) {
            var mainClass = ((CJRunModeWWW) runMode).getMainClass();
            ctx.validateMainItem(ctx.loadItem(mainClass));
        }

        var jsSink = useTranslator2 ?
            CJJSTranslator2.translate(ctx, runMode) :
            CJJSTranslator.translate(ctx, runMode);

        var finalOutPath = outPath;
        runMode.accept(new CJRunModeVisitor<Void, Void>() {

            private void handleWWW(CJRunModeWWWBase m) {
                var config = m.getConfig();
                var appdir = m.getAppdir();
                IO.delete(finalOutPath);
                if (config.has("www")) {
                    var keys = config.get("www").keys();
                    for (var key : keys) {
                        var src = findResourcePath(sourceRoots, appdir, key);
                        var reldest = config.get("www").get(key).getString();
                        var dest = FS.join(finalOutPath, reldest);
                        IO.copy(src, dest);
                    }
                }
                var filePath = FS.join(finalOutPath, "main.js");
                var sourceMapPath = filePath + ".map";
                var js = jsSink.getSource(filePath);
                var sourceMap = jsSink.getSourceMap(filePath);
                IO.writeFile(filePath, js);
                IO.writeFile(sourceMapPath, sourceMap);
            }

            private void handleCLI() {
                if (finalOutPath.equals("-")) {
                    IO.print(jsSink.getSource(""));
                } else {
                    var sourceMapPath = finalOutPath + ".map";
                    var js = jsSink.getSource(finalOutPath);
                    var sourceMap = jsSink.getSourceMap(finalOutPath);
                    IO.writeFile(finalOutPath, js);
                    IO.writeFile(sourceMapPath, sourceMap);
                }
            }

            @Override
            public Void visitMain(CJRunModeMain m, Void a) {
                handleCLI();
                return null;
            }

            @Override
            public Void visitTest(CJRunModeTest m, Void a) {
                handleCLI();
                return null;
            }

            @Override
            public Void visitWWW(CJRunModeWWW m, Void a) {
                handleWWW(m);
                return null;
            }

            @Override
            public Void visitNW(CJRunModeNW m, Void a) {
                handleWWW(m);
                var pkgjsonpath = IO.join(finalOutPath, "package.json");
                IO.writeFile(pkgjsonpath,
                        "{\"name\":\"" + m.getAppId() + "\",\"version\":\"0.0.1\",\"main\":\"index.html\"}");
                return null;
            }
        }, null);
    }

    private static enum Mode {
        Default, MainClass, SourceRoot, Out, App,
    }

    private static CJRunMode loadAppConfig(List<String> sourceRoots, String appId) {
        var colonIndex = appId.indexOf(':');
        if (colonIndex != -1) {
            for (var sourceRoot : sourceRoots) {
                var baseName = appId.substring(colonIndex + 1);
                var packageName = appId.substring(0, colonIndex);
                var appdir = FS.join(sourceRoot, packageName.replace("/", IO.separator()));
                var cjpath = FS.join(appdir, "CJ.json");
                if (FS.isFile(cjpath)) {
                    var blob = JSON.parse(IO.readFile(cjpath));
                    if (blob.has(baseName)) {
                        var config = blob.get(baseName);
                        var type = config.get("type").getString();
                        switch (type) {
                        case "www": {
                            return new CJRunModeWWW(appId, appdir, config);
                        }
                        case "nw": {
                            return new CJRunModeNW(appId, appdir, config);
                        }
                        default:
                            throw new RuntimeException(appId + " has unsupported app type " + type);
                        }
                    } else {
                        throw new RuntimeException("Traget " + baseName + " not found in " + packageName);
                    }
                }
            }
        }
        throw new RuntimeException("App target " + appId + " not found");
    }

    private static String findResourcePath(List<String> sourceRoots, String appdir, String givenPath) {
        if (givenPath.startsWith("/")) {
            var relpath = givenPath.substring(1);
            for (var sourceRoot : sourceRoots) {
                var candidate = FS.join(sourceRoot, relpath);
                if (FS.exists(candidate)) {
                    return candidate;
                }
            }
        } else {
            var candidate = FS.join(appdir, givenPath);
            if (FS.exists(candidate)) {
                return candidate;
            }
        }
        throw new RuntimeException("Resource " + givenPath + " not found");
    }
}
