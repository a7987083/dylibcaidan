#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: prepare-v0563-ui.py <iosruntimepatchmenu-dir>")
root = Path(sys.argv[1])
makefile = root / "Makefile"
bootstrap = root / "src" / "ZNDeferredBootstrap.mm"
skin = root / "src" / "ZNCyberpunkRuntimeSkin.mm"

if not makefile.exists() or not bootstrap.exists() or not skin.exists():
    raise SystemExit("missing sealed baseline or cyber UI source")

m = makefile.read_text()
needle = "ZonoePatchV03_FILES = "
lines = m.splitlines()
changed = False
for i, line in enumerate(lines):
    if line.startswith(needle):
        if "src/ZNCyberpunkRuntimeSkin.mm" not in line:
            lines[i] = line + " src/ZNCyberpunkRuntimeSkin.mm"
            changed = True
        break
else:
    raise SystemExit("ZonoePatchV03_FILES line not found")
makefile.write_text("\n".join(lines) + "\n")

b = bootstrap.read_text()
extern_anchor = 'extern "C" void ZNInstallFeatureBuilderUIDeferred(void);'
extern_line = 'extern "C" void ZNCyberpunkUIInstallDeferred(void);'
if extern_line not in b:
    if b.count(extern_anchor) != 1:
        raise SystemExit("feature builder extern anchor mismatch")
    b = b.replace(extern_anchor, extern_anchor + "\n" + extern_line, 1)
    changed = True

stage_anchor = 'ZNRunActivationStage(@"FeatureBuilderUI", ^{ ZNInstallFeatureBuilderUIDeferred(); });'
stage_line = 'ZNRunActivationStage(@"CyberpunkUI", ^{ ZNCyberpunkUIInstallDeferred(); });'
if stage_line not in b:
    if b.count(stage_anchor) != 1:
        raise SystemExit("feature builder stage anchor mismatch")
    b = b.replace(stage_anchor, stage_anchor + "\n        " + stage_line, 1)
    changed = True

replacements = {
    'button.layer.borderColor = [UIColor colorWithRed:0.42 green:0.55 blue:1.0 alpha:1.0].CGColor;':
        'button.layer.borderColor = [UIColor colorWithRed:0.05 green:0.88 blue:1.0 alpha:1.0].CGColor;',
    'button.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.92];':
        'button.backgroundColor = [UIColor colorWithRed:0.01 green:0.04 blue:0.10 alpha:0.96];',
    '[button setTitle:@"ZN" forState:UIControlStateNormal];':
        '[button setTitle:@"X" forState:UIControlStateNormal];',
    'button.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];':
        'button.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBlack];',
    'button.layer.shadowColor = UIColor.blackColor.CGColor;':
        'button.layer.shadowColor = [UIColor colorWithRed:0.72 green:0.06 blue:1.0 alpha:1.0].CGColor;',
    'button.layer.shadowOpacity = 0.28;':
        'button.layer.shadowOpacity = 0.72;',
    'button.layer.shadowRadius = 8.0;':
        'button.layer.shadowRadius = 12.0;',
}
for old, new in replacements.items():
    if old in b:
        b = b.replace(old, new, 1)
        changed = True
    elif new not in b:
        raise SystemExit(f"cold-launch UI anchor missing: {old}")
bootstrap.write_text(b)

if not changed:
    print("already prepared")
else:
    print("prepared sealed v0.5.6.2 baseline with UI-only cyberpunk skin")
