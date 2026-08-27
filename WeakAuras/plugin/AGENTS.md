# WEAKAURAS ADDON SOURCE — plugin

## OVERVIEW

WeakAuras v5.21.11 addon source, multi-flavor builds (Vanilla/TBC/Wrath/Cata/Mists via `X-Flavor` TOC metadata). 5 sub-addons, ~740 files. Read-only reference — tooling lives in `../source/`.

## STRUCTURE

```
plugin/
├── WeakAuras/            # Core engine (546 files)
├── WeakAurasOptions/     # Options UI (LoadOnDemand, 150 files)
├── WeakAurasTemplates/   # Trigger templates (25 files)
├── WeakAurasModelPaths/  # Model path data per flavor (12 files)
└── WeakAurasArchive/     # History/migration archive (5 files)
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Main TOC | `WeakAuras/WeakAuras_{Vanilla,TBC,Wrath,Cata,Mists}.toc` | Load order: Init → Compatibility → SubscribableObject → Features → Types_* → Prototypes → WeakAuras.lua → triggers → regions |
| Engine | `WeakAuras/WeakAuras.lua` | 6764 lines: SlashCmd, Login, Add/Delete, ApplyStatesToRegions |
| Flavor detection | `WeakAuras/Init.lua` | IsWrathClassic()/IsRetail() etc., parsed from X-Flavor |
| Event prototypes | `WeakAuras/Prototypes.lua` | 12573 lines, `Private.event_prototypes` |
| Generic triggers | `WeakAuras/GenericTrigger.lua` | 5430 lines, generic + custom triggers |
| Buff/Debuff triggers | `WeakAuras/BuffTrigger2.lua` | 4417 lines, `aura2` type |
| Data migration | `WeakAuras/Modernize.lua` | internalVersion 90 |
| Conditions | `WeakAuras/Conditions.lua` | dynamic Lua compilation |
| Region types | `WeakAuras/RegionTypes/` | icon/text/texture/aurabar/group/dynamicgroup... |
| Sub-regions | `WeakAuras/SubRegionTypes/` | background/border/glow/subtext/tick/model |
| Base components | `WeakAuras/BaseRegions/` | Texture/TextureCoords/progress bars |
| Region prototype | `WeakAuras/RegionTypes/RegionPrototype.lua` | create/modify/AddProperties |
| Import/export | `WeakAuras/Transmission.lua` | StringToTable/TableToString |
| Custom code env | `WeakAuras/AuraEnvironment.lua` | WA_GetUnitAura, WA_IterateGroupMembers |
| Templates | `WeakAurasTemplates/TriggerTemplates.lua` | + TriggerTemplatesData* per flavor |
| Options UI | `WeakAurasOptions/` | OptionsFrames/, RegionOptions/, AceGUI-Widgets/ |

## CONVENTIONS

- Every file: `local AddonName = ...` + `local Private = select(2, ...)`, guarded by `if not WeakAuras.IsLibsOK() then return end`
- Flavor branching via `WeakAuras.Is*()` functions; per-flavor files `Types_{Flavor}.lua`
- Region types: `default` + `properties` (display/setter/type) + `create(parent,data)` + `modify(parent,region,data)` + RegisterRegionType
- Event prototype args: `use_xxx` bool + `xxx` value + `xxx_operator`, compiled to Lua at runtime
- EmmyLua type annotations (`---@class Private`, `---@field`)

## NOTES

- Libs/ are third-party (LibDeflate, LibSerialize, AceGUI) — copies exist in `../source/` for CLI use
- SavedVariables: `WeakAurasSaved` (db.displays keyed by id)
- Login flow uses coroutine sharding (Private.Threads:Immediate)