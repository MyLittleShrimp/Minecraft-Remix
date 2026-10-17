class_name CampaignCatalog
extends RefCounted
const FINAL_LEVEL_ID := "the_end"
const PLANNED_CHAPTERS := 7
# Only shipped campaign scenes belong here; trials never unlock chapters.
const LEVELS := {
    "forest_ruins":{"scene":"res://scenes/levels/forest_level.tscn","title":"01 / 林地遗迹"},
    "spiderwood":{"scene":"res://scenes/levels/spiderwood_level.tscn","title":"02 / 蛛影林径"},
    "abandoned_mine":{"scene":"res://scenes/levels/mine_level.tscn","title":"03 / 废弃矿道"},
    "tidal_ruins":{"scene":"res://scenes/levels/tide_level.tscn","title":"04 / 潮汐遗迹"},
    "warped_border":{"scene":"res://scenes/levels/warped_level.tscn","title":"05 / 诡异边界"},
    "fortress_core":{"scene":"res://scenes/levels/fortress_level.tscn","title":"06 / 堡垒核心"},
    "the_end":{"scene":"res://scenes/levels/end_reunion.tscn","title":"07 / 末地 · 巨龙之巢"}
}
static func scene_path(id: String, segment: String="reunion") -> String:
    if id=="the_end": return {"reunion":"res://scenes/levels/end_reunion.tscn","portal":"res://scenes/levels/end_portal.tscn","dragon":"res://scenes/levels/end_dragon.tscn"}.get(segment,"")
    return LEVELS.get(id,{}).get("scene","")
static func title(id: String) -> String:
    return LEVELS.get(id,{}).get("title","未知关卡")

static func weapon_ids(id: String) -> Array[String]:
    if id in ["tidal_ruins","warped_border","fortress_core","the_end"]: return ["netherite_sword","bow","crossbow","axe","trident"]
    if id == "abandoned_mine": return ["netherite_sword","bow","crossbow","axe"]
    if id == "spiderwood": return ["netherite_sword","bow","crossbow"]
    return ["netherite_sword","bow"]

static func is_final_level(id: String) -> bool:
    return id==FINAL_LEVEL_ID

static func story_reward(id: String) -> Dictionary:
    if id=="fortress_core": return {"blaze_powder":3}
    return {"ender_pearl":3} if id=="warped_border" else {}
