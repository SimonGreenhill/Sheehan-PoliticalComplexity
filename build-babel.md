# Building the missing Babel tools from source

`TaxonReplacer` and the multi-height `TreeGrafter` exist only in Babel git master.
Rather than a full `ant` build (needs ant + sibling `beast2`, `BeastFX`, `BEASTLabs`
checkouts + a full BEAST2 compile), we recompiled just the changed sources against the
already-installed jars and patched them into the package jar.

Reproduce (paths are for this machine):

```bash
# 1. clone master
cd /Users/simon/Desktop
git clone --depth 1 https://github.com/rbouckaert/Babel.git

# 2. classpath = installed BEAST2 + package jars, EXCLUDING the babel jar being replaced
CP=$(find "/Applications/beast2/beast277/lib" \
         "/Users/simon/Library/Application Support/BEAST/2.7" \
         -name "*.jar" ! -name "*.src.jar" ! -name "Babel.addon.jar" | tr '\n' ':')
CP="$CP:/Users/simon/Library/Application Support/BEAST/2.7/Babel/lib/Babel.addon.jar.orig"

# 3. compile TreeCombiner (parent, needed by new TreeGrafter) + dplace tools
#    --release 17 because the launcher JRE only accepts class-file v61 (Java 17)
cd /Users/simon/Desktop/Babel
mkdir -p /tmp/bb
javac --release 17 -cp "$CP" -d /tmp/bb \
      src/babel/tools/TreeCombiner.java src/babel/tools/dplace/*.java

# 4. back up & patch the installed package jar
cd "/Users/simon/Library/Application Support/BEAST/2.7/Babel"
cp lib/Babel.addon.jar lib/Babel.addon.jar.orig   # (once)
cp version.xml version.xml.orig                    # (once)
jar uf lib/Babel.addon.jar -C /tmp/bb babel/tools/TreeCombiner.class \
                           -C /tmp/bb babel/tools/dplace
```

Then register `TaxonReplacer` in `version.xml` (so `applauncher` lists/finds it):
add next to the TreeGrafter entries —

```xml
<provider classname="babel.tools.dplace.TaxonReplacer"/>
...
<packageapp description="TaxonReplacer"
          class="babel.tools.dplace.TaxonReplacer"
          args="" />
```

Verify:
```bash
applauncher TaxonReplacer -help
```

To revert: restore `Babel.addon.jar.orig` and `version.xml.orig`.
```
```
