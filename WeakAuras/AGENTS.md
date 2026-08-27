# WEAKAURAS TOOLCHAIN — WeakAuras

## OVERVIEW

WoW addon source (plugin/) + Lua import-string parsing tools (source/) + release version data (release/). Two entry scripts: parse (string.txt → per-class .lua) and build (modified .lua → output.txt).

## STRUCTURE

```
WeakAuras/
├── parse_string.lua   # Entry: parse WA import string → per-class code files
├── build_string.lua   # Entry: modified per-class code → WA import string
├── plugin/            # WeakAuras addon source, 5 flavors (see plugin/AGENTS.md)
├── source/            # Lua tooling (LuaJIT, standalone)
│   ├── decode_wa.lua  # Core: StringToTable/ParseString/WriteResult/BuildStringFromOutput
│   ├── wa_cli.lua     # Shared: version scan/select (-l / arg / interactive)
│   ├── LibDeflate.lua # Compress/decompress + EncodeForPrint (64-char table)
│   └── LibSerialize.lua # Binary serialize/deserialize
└── release/           # Version data dirs (1.6.3/string.txt, output/, output.txt)
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Parse entry | `parse_string.lua` | `luajit parse_string.lua [ver|-l]` |
| Build entry | `build_string.lua` | `luajit build_string.lua [ver|-l]` |
| Core decode logic | `source/decode_wa.lua` | ExtractAuraCode maps code blocks with `path` for writeback |
| Version selection | `source/wa_cli.lua` | Shared by both entries |
| Import format | `source/LibDeflate.lua` | `!WA:2!` + EncodeForPrint + Deflate + Serialize |
| Version data | `release/1.6.3/` | string.txt (227KB input), output/*.lua, output.txt |
| Addon source | `plugin/` | see its AGENTS.md |

## CONVENTIONS

- Entry scripts delegate to `source/` modules; keep business logic out of entries
- Output files: `output/<aura-id>.lua` (code blocks marked `-- ===== name =====`) + `output/raw/transmit.bin` (lossless snapshot)
- `output/raw/` is required for build; never delete it
- Chinese filenames preserved for aura ids
- CLI contract: `-l` lists versions, arg selects version, no arg = interactive

## COMMANDS

```bash
luajit parse_string.lua [版本名|-l]   # parse string.txt → output/
luajit build_string.lua [版本名|-l]   # output/ (modified) → output.txt
```

## NOTES

- `WeakAuras/` dir is APFS case-insensitive; git tracks original case
- Build applies only modified blocks (matched by `-- ===== name =====`); missing files keep original code
- Version 1.6.3: 26 auras (虚空之花V1.613 group + VF_Core4.3/VF_Interface/VF_HekiliFollower + class APLs by 虎呗特/七叔/哀冬/夜雨/米娅 etc.)