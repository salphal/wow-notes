# MACRO DIRECTORY — 宏命令

## OVERVIEW

Class-specific WoW macros for 时光重铸. 34 files across 9 class subdirectories + shared utilities.

## STRUCTURE

```
宏命令/
├── 公共宏/       # Shared macros: comm, fm, target, utils, 天赋
├── 盗贼/         # 盗贼 (Rogue) — 5 files
├── 法师/         # 法师 (Mage) — 4 files
├── 战士/         # 战士 (Warrior) — 4 files
├── 牧师/         # 牧师 (Priest) — 2 files
├── 圣骑士/       # 圣骑士 (Paladin) — 4 files
├── 德鲁伊/       # 德鲁伊 (Druid) — 2 files
├── 猎人/         # 猎人 (Hunter) — 3 files
├── 死亡骑士/     # 死亡骑士 (Death Knight) — 1 file
└── READMD.md    # Entry point (typo: READMD vs README)
```

## WHERE TO LOOK

| Class | Directory | Files | Notes |
|-------|-----------|-------|-------|
| 盗贼 (Rogue) | `盗贼/` | comm, csz, hsz, mrz, zdz | csz=subtlety, hsz=assassination, mrz=combat |
| 法师 (Mage) | `法师/` | af, bf, comm, hf | af=arcane, bf=fire, hf=frost |
| 战士 (Warrior) | `战士/` | comm, fz, kbz, wqz | fz=prot, kbz=arms, wqz=fury |
| 牧师 (Priest) | `牧师/` | am, jlm | am=shadow, jlm=disciple |
| 圣骑士 (Paladin) | `圣骑士/` | cjq, dx, food, fq | cjq=retribution, fq=protection |
| 德鲁伊 (Druid) | `德鲁伊/` | nd, phd | nd=resto, phd=balance |
| 猎人 (Hunter) | `猎人/` | bb, comm, sw | bb=beast master, sw=survival |
| 死亡骑士 (DK) | `死亡骑士/` | bdk | bdk=blood |
| Shared utils | `公共宏/` | comm, fm, target, utils, 天赋 | Low-level utility macros |

## CONVENTIONS

- File names use class abbreviations + specialization acronyms (e.g., `cjq.md` = 惩戒骑/Retribution Paladin)
- Each specialization gets its own `.md` file; shared macros per class in `comm.md`
- Some classes include `wa.txt` for WeakAuras import strings
- `公共宏/` contains cross-class utility macros (focus, target, talent switching)

## NOTES

- `READMD.md` is a known typo (should be README.md) — preserved as-is