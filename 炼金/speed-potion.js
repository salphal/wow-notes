/**
 * 速度药水成本计算器
 *
 * 配方：
 * - 蛇信草 ×2
 * - 亚口鱼油 ×1（由小型亚口鱼 1.4 倍产出）
 * - 魔灌之瓶 ×1
 * => 产出数量为材料的 1.2 倍
 *
 * 单位：1 金 = 100 银
 */

// ========== 参数配置（请按实际价格修改） ==========

const FISH_PRICE_SILVER = 0;     // 小型亚口鱼单价（银）
const HERB_PRICE_SILVER = 0;     // 蛇信草单价（银）
const VIAL_PRICE_SILVER = 0;     // 魔灌之瓶单价（银）
const POTION_PRICE_SILVER = 0;   // 速度药水售价（银）

// ========== 配方常量 ==========

const FISH_TO_OIL_RATIO = 1.4;   // 1 条鱼 → 1.4 个油
const POTION_YIELD_RATIO = 1.2;  // 每份材料 → 1.2 瓶药水

const HERB_PER_BATCH = 2;
const OIL_PER_BATCH = 1;
const VIAL_PER_BATCH = 1;

const CRAFT_TIME_PER_POTION_SEC = 1.5; // 制作 1 瓶所需时间（秒）

// ========== 计算逻辑 ==========


function calcBatchCost() {
  const oilCost = (OIL_PER_BATCH / FISH_TO_OIL_RATIO) * FISH_PRICE_SILVER;
  const herbCost = HERB_PER_BATCH * HERB_PRICE_SILVER;
  const vialCost = VIAL_PER_BATCH * VIAL_PRICE_SILVER;
  return oilCost + herbCost + vialCost;
}

function calcPotionCostSilver() {
  return calcBatchCost() / POTION_YIELD_RATIO;
}

function silverToGold(silver) {
  return (silver / 100).toFixed(2);
}

/**
 * 将秒数格式化为 xxhxxmxxs
 */
function formatTime(seconds) {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.round(seconds % 60);
  let result = '';
  if (h > 0) result += `${h}h`;
  if (m > 0) result += `${m}m`;
  result += `${s}s`;
  return result;
}

// ========== 输出结果 ==========


function printResult() {
  console.log('========================================');
  console.log('        速度药水成本计算器');
  console.log('========================================\n');

  console.log('--- 参数配置 ---');
  console.log(`小型亚口鱼单价：${FISH_PRICE_SILVER} 银`);
  console.log(`蛇信草单价：    ${HERB_PRICE_SILVER} 银`);
  console.log(`魔灌之瓶单价：  ${VIAL_PRICE_SILVER} 银`);
  console.log(`速度药水售价：  ${POTION_PRICE_SILVER} 银\n`);

  console.log('--- 配方信息 ---');
  console.log(`蛇信草 ×${HERB_PER_BATCH}`);
  console.log(`亚口鱼油 ×${OIL_PER_BATCH}（小型亚口鱼 ×${(OIL_PER_BATCH / FISH_TO_OIL_RATIO).toFixed(2)}）`);
  console.log(`魔灌之瓶 ×${VIAL_PER_BATCH}`);
  console.log(`每份材料产出：${POTION_YIELD_RATIO} 瓶\n`);

  const costPerPotionSilver = calcPotionCostSilver();
  const costPerPotionGold = silverToGold(costPerPotionSilver);
  const profitPerPotionSilver = POTION_PRICE_SILVER - costPerPotionSilver;
  const profitPerPotionGold = silverToGold(profitPerPotionSilver);

  console.log('--- 计算结果 ---');
  console.log(`每瓶成本：      ${costPerPotionSilver.toFixed(2)} 银（${costPerPotionGold} 金）`);
  console.log(`每瓶售价：      ${POTION_PRICE_SILVER} 银`);
  console.log(`每瓶利润：      ${profitPerPotionSilver.toFixed(2)} 银（${profitPerPotionGold} 金）`);
  console.log(`利润率：        ${POTION_PRICE_SILVER > 0 ? ((profitPerPotionSilver / costPerPotionSilver) * 100).toFixed(1) : 'N/A'}%\n`);

  console.log('--- 批量成本 ---');
  const quantities = [1, 100, 2000];
  for (const qty of quantities) {
    const totalCostSilver = costPerPotionSilver * qty;
    const totalCostGold = silverToGold(totalCostSilver);
    const totalRevenueSilver = POTION_PRICE_SILVER * qty;
    const totalRevenueGold = silverToGold(totalRevenueSilver);
    const totalProfitSilver = totalRevenueSilver - totalCostSilver;
    const totalProfitGold = silverToGold(totalProfitSilver);
    const craftTime = formatTime(qty * CRAFT_TIME_PER_POTION_SEC);
    console.log(`${qty} 瓶成本：${totalCostSilver.toFixed(2)} 银（${totalCostGold} 金）`);
    console.log(`${qty} 瓶耗时：${craftTime}`);
    if (POTION_PRICE_SILVER > 0) {
      console.log(`${qty} 瓶收入：${totalRevenueSilver.toFixed(2)} 银（${totalRevenueGold} 金）`);
      console.log(`${qty} 瓶利润：${totalProfitSilver.toFixed(2)} 银（${totalProfitGold} 金）`);
    }
    console.log('');
  }


  console.log('========================================');
}

// ========== 运行 ==========

printResult();
