###

````text


#showtooltip 附魔
-- 点击动作条第1格按钮( 通常这里放的是“分解 Disenchant”技能 )
/click ActionButton1
-- 点击专业技能窗口里的 "制造/执行" 按钮( 执行当前选择的附魔或分解 )
/click TradeSkillCreateButton
-- 使用背包第0个包( 背包 )里的第1个物品( 通常是要分解的装备 )
/use 0 1
-- 自动点击弹出的确认框的“确定”按钮( 确认分解装备 )
/click StaticPopup1Button1


````
