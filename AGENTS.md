# PROJECT KNOWLEDGE BASE

**Generated:** 2026-08-27
**Commit:** 6a02a1e
**Branch:** main

## OVERVIEW

WoW notes for 时光重铸 (Time Reforged) private server: class macros, profession guides, solo farming notes, addon setup, WeakAuras addon source, and WA import-string parsing tools. Markdown knowledge base + Lua tooling, no build system.

## STRUCTURE

```
wow-notes/
├── WeakAuras/        # WA plugin source (plugin/) + parse tools (source/) + version data (release/)
├── 宏命令/           # Class macros — 9 Chinese-named class dirs, 34 files
├── 专业/             # Profession guides: engineering, cooking, jewelcrafting
├── 插件/             # Addon setup guide with screenshots
├── 炼金/             # Alchemy automation (speed-potion.js + 速度药水.md)
└── 单刷/             # Solo farming notes
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Rogue macros | `宏命令/盗贼/` | 5 files: comm, csz, hsz, mrz, zdz |
| Mage macros | `宏命令/法师/` | 4 files: af, bf, comm, hf |
| Warrior macros | `宏命令/战士/` | 4 files: comm, fz, kbz, wqz |
| Priest macros | `宏命令/牧师/` | 2 files: am, jlm |
| Shared macro utilities | `宏命令/公共宏/` | comm, fm, target, utils, 天赋 |
| Paladin macros | `宏命令/圣骑士/` | 4 files: cjq, dx, food, fq |
| Druid macros | `宏命令/德鲁伊/` | 2 files: nd, phd |
| Hunter macros | `宏命令/猎人/` | 2 files: bb, comm |
| Death Knight macros | `宏命令/死亡骑士/` | 1 file: bdk |
| WA plugin source | `WeakAuras/plugin/` | 5-flavor addon source (see its AGENTS.md) |
| WA parse tools | `WeakAuras/source/` | decode_wa.lua + wa_cli.lua + LibDeflate + LibSerialize |
| Parse entry script | `WeakAuras/parse_string.lua` | string.txt → output/*.lua per-class |
| Build entry script | `WeakAuras/build_string.lua` | modified output/*.lua → output.txt |
| Version data | `WeakAuras/release/1.6.3/` | string.txt (input) + output/ + output.txt |
| Engineering guide | `专业/工程/` | |
| Cooking guide | `专业/烹饪/` | + dailies subdir + asserts (images) |
| Jewelcrafting guide | `专业/珠宝/` | |
| Addon setup | `插件/` | 7 screenshots + guide |
| Alchemy automation | `炼金/` | speed-potion.js + guide |

## CONVENTIONS

- All content in Chinese (zh-CN)
- Class macros organized as Chinese-named directories under `宏命令/` (盗贼, 法师, 战士, 牧师, 圣骑士, 德鲁伊, 猎人, 死亡骑士, 公共宏)
- README.md used as entry point for each topic directory
- `.lua` in `WeakAuras/source/` are standalone tools (LuaJIT), not WoW addon code
- `.js` files are automation scripts (Node.js)

## COMMANDS

```bash
# WA import string → per-class code files
cd WeakAuras && luajit parse_string.lua [版本名|-l]

# modified per-class code → WA import string
cd WeakAuras && luajit build_string.lua [版本名|-l]
```

## NOTES

- `宏命令/READMD.md` is a typo (READMD vs README) — original naming
- 20 PNG screenshots in `专业/烹饪/asserts/` for cooking ingredient reference
- `虚空之花/` directory removed; its 3 WA scripts are now `WeakAuras/release/1.6.3/output/` class files
- Top-level `WeakAuras/` dir is APFS case-insensitive — git shows original case `WeakAuras`