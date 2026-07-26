

### 出血

```text


#showtooltip 出血
/startattack
/cast [@focus,exists,harm,nodead][@mouseover,exists,harm,nodead][harm,nodead] 出血
/use [@player,combat] 10
/cast 预谋

wwwwww

```

### 刺骨

```text


#showtooltip 刺骨
/startattack
/cast [@focus,exists,harm,nodead][@mouseover,exists,harm,nodead][harm,nodead] 刺骨
/use [@player,combat] 10


```

### 死亡印记

```text


#showtooltip 死亡印记
/startattack
/cast [@focus,exists,harm,nodead][@mouseover,exists,harm,nodead][harm,nodead] 死亡印记
/use [@player,combat] 10


```

### 锁喉

```text


#showtooltip 锁喉
/startattack
/cast [@focus,exists,harm,nodead][@mouseover,exists,harm,nodead][harm,nodead] 锁喉
/use [@player,combat] 10
/cast 预谋


```


### 伏击

```text


#showtooltip 伏击
/startattack
/cast 预谋
/cast [@focus,exists,harm,nodead][@mouseover,exists,harm,nodead][harm,nodead] 伏击
/use [@player,combat] 10


```

### 伏击

```text


#showtooltip 割裂
/startattack
/cast [@focus,exists,harm,nodead][@mouseover,exists,harm,nodead][harm,nodead] 割裂
/use [@player,combat] 10


```


### 影步

```text


#showtooltip 锁喉
/startattack
/cast 暗影步
/cast 预谋
/cast 锁喉
/use [@player,combat] 10


```

### 影步

```text


/showtooltip
/stopattack
/castsequence reset=2/combat 伏击,割裂
/startattack

/showtooltip
/castsequence reset=6/combat 暗影步,预谋,锁喉
/startattack

/showtooltip
/castsequence reset=6/combat 割裂,出血,破甲
/startattack

/showtooltip
/castsequence reset=6/combat 死亡印记,刺骨
/startattack


```

## 暗影

### 暗锁

```text


/showtooltip
/stopattack
/castsequence reset=2/combat 伏击,割裂
/startattack

/showtooltip
/castsequence reset=2/combat 伏击,刺骨,伏击,刺骨,锁喉,死亡印记,伏击
/startattack


```a

### 暗伏

```text


/showtooltip
/stopattack
/castsequence reset=2/combat 伏击,割裂
/startattack

/showtooltip
/castsequence reset=2/combat 伏击,刺骨,伏击,刺骨,锁喉,死亡印记,伏击
/startattack


```














