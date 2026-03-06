# 毒蛇神殿

### 传核

```text


#showtooltip 传核
/use 污染之核
/大喊 我把污染之核传给:%T了!
/script SendChatMessage("我把污染之核传给你了，%T","whisper",GetDefaultLanguage("target"),UnitName("target"))
/script SetRaidTarget("target",2)


```