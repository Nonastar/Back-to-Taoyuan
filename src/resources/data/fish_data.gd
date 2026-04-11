extends RefCounted
class_name FishData

## FishData - 鱼类数据定义
## 包含所有60种鱼类的定义
## 参考: P02 钓鱼系统 GDD

# 鱼类数据格式:
# "fish_id": {
#     "name": "名称",
#     "description": "描述",
#     "base_price": 基础售价,
#     "rarity": 稀有度 (0=普通, 1=优质, 2=精品, 3=传说),
#     "difficulty": 难度 (1-10),
#     "exp_value": 经验值,
#     "locations": ["地点"],
#     "seasons": [季节],
#     "hours": [小时],
#     "is_legendary": 是否传说
# }

const FISH_DATA: Dictionary = {
	# ========== 森林池塘 (forest_pond) ==========
	"fish_carp": {
		"name": "鲫鱼",
		"description": "常见的淡水鱼，适应性强。",
		"base_price": 30,
		"rarity": 0,
		"difficulty": 1,
		"exp_value": 5,
		"locations": ["forest_pond"],
		"seasons": [0, 1, 2, 3],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21],
		"is_legendary": false
	},
	"fish_small_carp": {
		"name": "小鲫鱼",
		"description": "体型较小的鲫鱼苗。",
		"base_price": 15,
		"rarity": 0,
		"difficulty": 1,
		"exp_value": 3,
		"locations": ["forest_pond"],
		"seasons": [0, 1, 2],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
		"is_legendary": false
	},
	"fish_crayfish": {
		"name": "小龙虾",
		"description": "淡水甲壳类，味道鲜美。",
		"base_price": 45,
		"rarity": 0,
		"difficulty": 2,
		"exp_value": 8,
		"locations": ["forest_pond"],
		"seasons": [0, 1],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
		"is_legendary": false
	},
	"fish_catfish": {
		"name": "鲶鱼",
		"description": "夜行性鱼类，白天藏在水底。",
		"base_price": 55,
		"rarity": 0,
		"difficulty": 3,
		"exp_value": 10,
		"locations": ["forest_pond", "river"],
		"seasons": [0, 1, 2],
		"hours": [0, 1, 2, 3, 4, 5, 21, 22, 23],
		"is_legendary": false
	},
	"fish_green_frog": {
		"name": "青蛙",
		"description": "两栖动物，不算真正的鱼。",
		"base_price": 25,
		"rarity": 0,
		"difficulty": 1,
		"exp_value": 5,
		"locations": ["forest_pond"],
		"seasons": [0, 1],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18],
		"is_legendary": false
	},
	"fish_grass_carp": {
		"name": "草鱼",
		"description": "体型较大的淡水鱼，以草为食。",
		"base_price": 60,
		"rarity": 1,
		"difficulty": 4,
		"exp_value": 15,
		"locations": ["forest_pond", "river"],
		"seasons": [0, 1, 2, 3],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
		"is_legendary": false
	},
	"fish_snail": {
		"name": "田螺",
		"description": "淡水螺类，可用于烹饪。",
		"base_price": 20,
		"rarity": 0,
		"difficulty": 1,
		"exp_value": 3,
		"locations": ["forest_pond"],
		"seasons": [0, 1, 2],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18],
		"is_legendary": false
	},

	# ========== 河流 (river) ==========
	"fish_sardine": {
		"name": "沙丁鱼",
		"description": "小型海水鱼，成群游动。",
		"base_price": 35,
		"rarity": 0,
		"difficulty": 2,
		"exp_value": 6,
		"locations": ["river"],
		"seasons": [0, 1, 2, 3],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
		"is_legendary": false
	},
	"fish_bass": {
		"name": "鲈鱼",
		"description": "肉食性淡水鱼，钓鱼的经典目标。",
		"base_price": 55,
		"rarity": 0,
		"difficulty": 3,
		"exp_value": 10,
		"locations": ["river"],
		"seasons": [0, 1, 2],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
		"is_legendary": false
	},
	"fish_trout": {
		"name": "鳟鱼",
		"description": "对水质要求高的冷水鱼。",
		"base_price": 75,
		"rarity": 1,
		"difficulty": 4,
		"exp_value": 15,
		"locations": ["river", "mountain_lake"],
		"seasons": [0, 2, 3],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
		"is_legendary": false
	},
	"fish_eel": {
		"name": "鳗鱼",
		"description": "细长的洄游鱼类，味道鲜美。",
		"base_price": 85,
		"rarity": 1,
		"difficulty": 5,
		"exp_value": 18,
		"locations": ["river"],
		"seasons": [1, 2],
		"hours": [18, 19, 20, 21, 22, 23],
		"is_legendary": false
	},
	"fish_perch": {
		"name": "鳜鱼",
		"description": "淡水名贵鱼种，口感极佳。",
		"base_price": 95,
		"rarity": 1,
		"difficulty": 5,
		"exp_value": 20,
		"locations": ["river", "mountain_lake"],
		"seasons": [0, 1, 2],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
		"is_legendary": false
	},
	"fish_herring": {
		"name": "鲱鱼",
		"description": "小型海水鱼，有强烈的气味。",
		"base_price": 40,
		"rarity": 0,
		"difficulty": 2,
		"exp_value": 6,
		"locations": ["river", "ocean"],
		"seasons": [0, 2, 3],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14],
		"is_legendary": false
	},
	"fish_anchovy": {
		"name": "凤尾鱼",
		"description": "小型银白色鱼类，常被做成罐头。",
		"base_price": 30,
		"rarity": 0,
		"difficulty": 1,
		"exp_value": 5,
		"locations": ["river", "ocean"],
		"seasons": [1, 2],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
		"is_legendary": false
	},
	"fish_crab": {
		"name": "河蟹",
		"description": "淡水蟹类，肉质鲜嫩。",
		"base_price": 65,
		"rarity": 1,
		"difficulty": 3,
		"exp_value": 12,
		"locations": ["river"],
		"seasons": [0, 1, 2],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
		"is_legendary": false
	},
	"fish_shrimp": {
		"name": "河虾",
		"description": "小型淡水虾，繁殖迅速。",
		"base_price": 40,
		"rarity": 0,
		"difficulty": 2,
		"exp_value": 7,
		"locations": ["river"],
		"seasons": [0, 1, 2],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
		"is_legendary": false
	},

	# ========== 山顶湖泊 (mountain_lake) ==========
	"fish_mountain_trout": {
		"name": "山鳟",
		"description": "生活在高海拔冷水中的珍稀鳟鱼。",
		"base_price": 120,
		"rarity": 1,
		"difficulty": 6,
		"exp_value": 25,
		"locations": ["mountain_lake"],
		"seasons": [0, 3],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14],
		"is_legendary": false
	},
	"fish_arctic_char": {
		"name": "北极红点鲑",
		"description": "冷水鱼类，体色艳丽。",
		"base_price": 150,
		"rarity": 2,
		"difficulty": 7,
		"exp_value": 30,
		"locations": ["mountain_lake"],
		"seasons": [3],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13],
		"is_legendary": false
	},
	"fish_golden_trout": {
		"name": "金鳟",
		"description": "变异的虹鳟，通体金黄。",
		"base_price": 200,
		"rarity": 2,
		"difficulty": 7,
		"exp_value": 40,
		"locations": ["mountain_lake"],
		"seasons": [0, 3],
		"hours": [6, 7, 8, 9],
		"is_legendary": false
	},
	"fish_lake_sturgeon": {
		"name": "湖鲟",
		"description": "古老的淡水鱼类，寿命极长。",
		"base_price": 180,
		"rarity": 2,
		"difficulty": 8,
		"exp_value": 35,
		"locations": ["mountain_lake"],
		"seasons": [0, 1, 2, 3],
		"hours": [6, 7, 8, 9, 10, 11],
		"is_legendary": false
	},
	"fish_ice_fish": {
		"name": "冰鱼",
		"description": "冬季在冰层下活动的鱼类。",
		"base_price": 100,
		"rarity": 1,
		"difficulty": 5,
		"exp_value": 20,
		"locations": ["mountain_lake"],
		"seasons": [3],
		"hours": [10, 11, 12, 13, 14, 15, 16],
		"is_legendary": false
	},
	"fish_grayling": {
		"name": "茴鱼",
		"description": "色彩斑斓的冷水小鱼。",
		"base_price": 80,
		"rarity": 1,
		"difficulty": 4,
		"exp_value": 15,
		"locations": ["mountain_lake"],
		"seasons": [0, 3],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
		"is_legendary": false
	},
	"fish_white_fish": {
		"name": "白鱼",
		"description": "肉质细嫩的高山冷水鱼。",
		"base_price": 90,
		"rarity": 1,
		"difficulty": 4,
		"exp_value": 16,
		"locations": ["mountain_lake"],
		"seasons": [0, 1, 2, 3],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
		"is_legendary": false
	},

	# ========== 海洋 (ocean) ==========
	"fish_tuna": {
		"name": "金枪鱼",
		"description": "大型远洋鱼类，肉质鲜美。",
		"base_price": 150,
		"rarity": 1,
		"difficulty": 6,
		"exp_value": 30,
		"locations": ["ocean"],
		"seasons": [0, 1, 2, 3],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
		"is_legendary": false
	},
	"fish_salmon": {
		"name": "三文鱼",
		"description": "洄游鱼类，产卵季节体色变红。",
		"base_price": 130,
		"rarity": 1,
		"difficulty": 5,
		"exp_value": 25,
		"locations": ["ocean", "river"],
		"seasons": [1, 2],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
		"is_legendary": false
	},
	"fish_swordfish": {
		"name": "剑鱼",
		"description": "海洋顶级掠食者，速度极快。",
		"base_price": 280,
		"rarity": 2,
		"difficulty": 8,
		"exp_value": 50,
		"locations": ["ocean"],
		"seasons": [0, 1, 2],
		"hours": [6, 7, 8, 9, 10],
		"is_legendary": false
	},
	"fish_marlin": {
		"name": "马林鱼",
		"description": "长嘴的大型鱼类，钓起来很有挑战性。",
		"base_price": 320,
		"rarity": 2,
		"difficulty": 9,
		"exp_value": 60,
		"locations": ["ocean"],
		"seasons": [1, 2],
		"hours": [6, 7, 8, 9, 10],
		"is_legendary": false
	},
	"fish_shark": {
		"name": "鲨鱼",
		"description": "海洋霸主，危险但价值极高。",
		"base_price": 400,
		"rarity": 2,
		"difficulty": 9,
		"exp_value": 70,
		"locations": ["ocean"],
		"seasons": [1, 2],
		"hours": [6, 7, 8],
		"is_legendary": false
	},
	"fish_octopus": {
		"name": "章鱼",
		"description": "聪明的海洋生物，触手很多。",
		"base_price": 110,
		"rarity": 1,
		"difficulty": 5,
		"exp_value": 22,
		"locations": ["ocean"],
		"seasons": [0, 1, 2, 3],
		"hours": [0, 1, 2, 3, 4, 5, 21, 22, 23],
		"is_legendary": false
	},
	"fish_squid": {
		"name": "鱿鱼",
		"description": "夜间活动的头足类动物。",
		"base_price": 95,
		"rarity": 1,
		"difficulty": 4,
		"exp_value": 18,
		"locations": ["ocean"],
		"seasons": [0, 1, 2, 3],
		"hours": [0, 1, 2, 3, 4, 5, 21, 22, 23],
		"is_legendary": false
	},
	"fish_lobster": {
		"name": "龙虾",
		"description": "珍贵的海鲜，甲壳坚硬。",
		"base_price": 200,
		"rarity": 2,
		"difficulty": 7,
		"exp_value": 40,
		"locations": ["ocean"],
		"seasons": [0, 1, 2, 3],
		"hours": [0, 1, 2, 3, 4, 5],
		"is_legendary": false
	},
	"fish_sea_urchin": {
		"name": "海胆",
		"description": "棘皮动物，味道鲜美。",
		"base_price": 150,
		"rarity": 1,
		"difficulty": 4,
		"exp_value": 25,
		"locations": ["ocean"],
		"seasons": [0, 1, 2, 3],
		"hours": [6, 7, 8, 9, 10, 11],
		"is_legendary": false
	},
	"fish_puffer": {
		"name": "河豚",
		"description": "遇险时会鼓起身体，有毒但极美味。",
		"base_price": 180,
		"rarity": 2,
		"difficulty": 6,
		"exp_value": 35,
		"locations": ["ocean"],
		"seasons": [0, 1],
		"hours": [12, 13, 14, 15, 16, 17],
		"is_legendary": false
	},
	"fish_clownfish": {
		"name": "小丑鱼",
		"description": "色彩鲜艳的热带鱼，常与海葵共生。",
		"base_price": 75,
		"rarity": 1,
		"difficulty": 3,
		"exp_value": 12,
		"locations": ["ocean"],
		"seasons": [1],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
		"is_legendary": false
	},

	# ========== 女巫沼泽 (witch_swamp) ==========
	"fish_swamp_eel": {
		"name": "沼泽鳗",
		"description": "适应了沼泽环境的鳗鱼。",
		"base_price": 80,
		"rarity": 1,
		"difficulty": 4,
		"exp_value": 15,
		"locations": ["witch_swamp"],
		"seasons": [0, 1, 2, 3],
		"hours": [18, 19, 20, 21, 22, 23, 0, 1, 2, 3],
		"is_legendary": false
	},
	"fish_bullfrog": {
		"name": "牛蛙",
		"description": "大型蛙类，叫声洪亮。",
		"base_price": 50,
		"rarity": 0,
		"difficulty": 2,
		"exp_value": 8,
		"locations": ["witch_swamp"],
		"seasons": [0, 1],
		"hours": [18, 19, 20, 21, 22],
		"is_legendary": false
	},
	"fish_witch_fish": {
		"name": "巫鱼",
		"description": "据说是被女巫诅咒的鱼类，会发光。",
		"base_price": 250,
		"rarity": 2,
		"difficulty": 7,
		"exp_value": 45,
		"locations": ["witch_swamp"],
		"seasons": [1, 2],
		"hours": [0, 1, 2, 3],
		"is_legendary": false
	},
	"fish_swamp_lamprey": {
		"name": "七鳃鳗",
		"description": "古老的寄生鱼类，外形可怖。",
		"base_price": 130,
		"rarity": 1,
		"difficulty": 5,
		"exp_value": 22,
		"locations": ["witch_swamp"],
		"seasons": [0, 2, 3],
		"hours": [0, 1, 2, 3, 4, 5],
		"is_legendary": false
	},
	"fish_snake_head": {
		"name": "黑鱼",
		"description": "凶猛的淡水鱼，能在空气中呼吸。",
		"base_price": 90,
		"rarity": 1,
		"difficulty": 4,
		"exp_value": 16,
		"locations": ["witch_swamp"],
		"seasons": [0, 1],
		"hours": [6, 7, 8, 9, 10, 11, 18, 19, 20, 21, 22, 23],
		"is_legendary": false
	},
	"fish_mudfish": {
		"name": "泥鳅",
		"description": "底栖鱼类，能在泥中生存。",
		"base_price": 35,
		"rarity": 0,
		"difficulty": 2,
		"exp_value": 6,
		"locations": ["witch_swamp"],
		"seasons": [0, 1, 2, 3],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18],
		"is_legendary": false
	},
	"fish_leech": {
		"name": "水蛭",
		"description": "吸血的环节动物，有药用价值。",
		"base_price": 40,
		"rarity": 0,
		"difficulty": 2,
		"exp_value": 6,
		"locations": ["witch_swamp"],
		"seasons": [0, 1, 2],
		"hours": [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
		"is_legendary": false
	},

	# ========== 秘密池塘 (secret_pond) - 传说鱼专属 ==========
	"fish_koi": {
		"name": "锦鲤",
		"description": "传说中的观赏鱼，色彩斑斓，价值连城。",
		"base_price": 1000,
		"rarity": 3,
		"difficulty": 10,
		"exp_value": 100,
		"locations": ["secret_pond"],
		"seasons": [0, 1, 2, 3],
		"hours": [6, 7, 8, 9, 10, 11],
		"is_legendary": true,
		"daily_limit": 1
	},
	"fish_golden_koi": {
		"name": "金鳞锦鲤",
		"description": "全身金色的锦鲤，极其稀有。",
		"base_price": 2000,
		"rarity": 3,
		"difficulty": 10,
		"exp_value": 150,
		"locations": ["secret_pond"],
		"seasons": [1, 2],
		"hours": [6, 7, 8],
		"is_legendary": true,
		"daily_limit": 1
	},
	"fish_dragon_fish": {
		"name": "龙鱼",
		"description": "远古鱼类，据说拥有龙的血脉。",
		"base_price": 3000,
		"rarity": 3,
		"difficulty": 10,
		"exp_value": 200,
		"locations": ["secret_pond", "ocean"],
		"seasons": [1],
		"hours": [6, 7, 8],
		"is_legendary": true,
		"daily_limit": 1
	},
	"fish_phoenix_fish": {
		"name": "凤凰鱼",
		"description": "传说中如凤凰般绚烂的鱼。",
		"base_price": 2500,
		"rarity": 3,
		"difficulty": 10,
		"exp_value": 180,
		"locations": ["secret_pond"],
		"seasons": [0],
		"hours": [6, 7],
		"is_legendary": true,
		"daily_limit": 1
	},
	"fish_rainbow_fish": {
		"name": "彩虹鱼",
		"description": "会变换七彩光芒的神奇鱼类。",
		"base_price": 1500,
		"rarity": 3,
		"difficulty": 10,
		"exp_value": 120,
		"locations": ["secret_pond", "river"],
		"seasons": [0, 1, 2, 3],
		"hours": [0, 1],
		"is_legendary": true,
		"daily_limit": 1
	},
	"fish_mystic_turtle": {
		"name": "灵龟",
		"description": "不是鱼但可以钓到，被视为祥瑞。",
		"base_price": 1800,
		"rarity": 3,
		"difficulty": 10,
		"exp_value": 150,
		"locations": ["secret_pond"],
		"seasons": [0, 1, 2, 3],
		"hours": [4, 5],
		"is_legendary": true,
		"daily_limit": 1
	}
}

# ========== 工具函数 ==========

## 获取所有鱼类ID
static func get_all_fish_ids() -> Array:
	return FISH_DATA.keys()

## 获取鱼类数据
static func get_fish_data(fish_id: String) -> Dictionary:
	return FISH_DATA.get(fish_id, {})

## 检查鱼类是否存在
static func has_fish(fish_id: String) -> bool:
	return FISH_DATA.has(fish_id)

## 按地点获取鱼类列表
static func get_fish_by_location(location: String) -> Array:
	var result = []
	for fish_id in FISH_DATA:
		var data = FISH_DATA[fish_id]
		if location in data.get("locations", []):
			result.append(fish_id)
	return result

## 按稀有度获取鱼类列表
static func get_fish_by_rarity(rarity: int) -> Array:
	var result = []
	for fish_id in FISH_DATA:
		var data = FISH_DATA[fish_id]
		if data.get("rarity", 0) == rarity:
			result.append(fish_id)
	return result

## 获取传说鱼列表
static func get_legendary_fish() -> Array:
	return get_fish_by_rarity(3)

## 获取所有钓鱼地点
static func get_all_locations() -> Array:
	var locations = []
	var seen = {}
	for fish_id in FISH_DATA:
		var data = FISH_DATA[fish_id]
		for loc in data.get("locations", []):
			if not seen.has(loc):
				seen[loc] = true
				locations.append(loc)
	return locations

## 获取地点显示名称
static func get_location_display_name(location: String) -> String:
	var names = {
		"forest_pond": "森林池塘",
		"river": "河流",
		"mountain_lake": "山顶湖泊",
		"ocean": "海洋",
		"witch_swamp": "女巫沼泽",
		"secret_pond": "秘密池塘"
	}
	return names.get(location, location)
