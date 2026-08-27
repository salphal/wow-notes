# PROJECT KNOWLEDGE BASE

**Generated:** 2026-08-27
**Commit:** 9e49bee
**Branch:** main

## OVERVIEW

WoW notes for 时光重铸 (Time Reforged) private server: class macros, profession guides, solo farming notes, addon setup, and WeakAuras scripts. All markdown-based, no build system.

## STRUCTURE

```
wow-notes/
├── 宏命令/       # Class-specific macros — 9 classes, 34 files
├── 专业/         # Profession guides: engineering, cooking, jewelcrafting
├── 虚空之花/     # Void Flower mode: class WA scripts (.lua)
├── 插件/         # Addon setup guide with screenshots
├── 炼金/         # Alchemy automation (speed-potion.js + 速度药水.md)
└── 单刷/         # Solo farming notes
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
| Engineering guide | `专业/工程/` | |
| Cooking guide | `专业/烹饪/` | + dailies subdir + asserts (images) |
| Jewelcrafting guide | `专业/珠宝/` | |
| Void Flower WAs | `虚空之花/` | 3 .lua WA scripts |
| Addon setup | `插件/` | 7 screenshots + guide |
| Alchemy automation | `炼金/` | speed-potion.js + guide |

## CONVENTIONS

- All content in Chinese (zh-CN)
- Class macros organized as separate Chinese-named directories under `宏命令/` (盗贼, 法师, 战士, 牧师, 圣骑士, 德鲁伊, 猎人, 死亡骑士, 公共宏)
- README.md used as entry point for each topic directory
- `.lua` files in `虚空之花/` are WeakAuras import strings
- `.js` files are automation scripts (Node.js)

## COMMANDS

No build/test/dev commands — this is a static markdown knowledge base.

## NOTES

- `宏命令/READMD.md` is a typo (READMD vs README) — original naming
- 20 PNG screenshots in `专业/烹饪/asserts/` for cooking ingredient reference
- WA scripts in `虚空之花/` may have different server-specific configurations