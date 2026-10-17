extends Node
## Live campaign ledger; SaveManager persists committed checkpoints separately.
## A cleared level settles once; replaying it starts from its original entry
## balance, so R cannot repeatedly add the same victory reward.
var balance: int = 0
var level_id: StringName = &""
var entry_balance: int = 0
var food: float = 20.0
var entry_food: float = 20.0
var ticket: int = 0
var settled_ticket: int = -1
var travel_equipment: Dictionary = {}
var story_items: Dictionary = {"ender_pearl":0,"blaze_powder":0}
var entry_story_items: Dictionary = {"ender_pearl":0,"blaze_powder":0}

func enter_level(id: StringName, replay: bool = false) -> Dictionary:
    if id != level_id:
        # A different level may only take ownership after the current one clears.
        if level_id != &"" and settled_ticket != ticket: return {}
        entry_story_items=story_items.duplicate(true)
        entry_balance = balance
        # Food is a per-level budget; emeralds remain the campaign resource.
        entry_food = HungerComponent.MAXIMUM
        food = entry_food
        level_id = id
        ticket += 1
        settled_ticket = -1
    elif replay:
        story_items=entry_story_items.duplicate(true)
        balance = entry_balance
        food = entry_food
        ticket += 1
        settled_ticket = -1
    return {"id": level_id, "ticket": ticket, "emeralds": entry_balance, "food": entry_food}

func complete_level(id: StringName, token: int, remaining: int, remaining_food: float, rewards: Dictionary = {}) -> bool:
    if id != level_id or token != ticket or settled_ticket == token or remaining < 0 or not is_finite(remaining_food) or remaining_food<0 or remaining_food>20:
        return false
    if rewards!=CampaignCatalog.story_reward(str(id)): return false
    story_items=entry_story_items.duplicate(true)
    for key in rewards: story_items[key]=int(story_items.get(key,0))+int(rewards[key])
    if id==&"the_end": story_items={"ender_pearl":0,"blaze_powder":0}
    balance = remaining
    food = remaining_food
    settled_ticket = token
    return true

func new_campaign() -> void:
    travel_equipment.clear()
    story_items={"ender_pearl":0,"blaze_powder":0}
    entry_story_items=story_items.duplicate(true)
    balance = 0
    entry_balance = 0
    food = 20.0
    entry_food = 20.0
    level_id = &""
    ticket += 1
    settled_ticket = -1

func restore_entry(emeralds: int, inventory: Dictionary = {"ender_pearl":0,"blaze_powder":0}) -> void:
    # Fresh tickets reject stale callbacks; never deserialize transient attack IDs.
    new_campaign()
    story_items=inventory.duplicate(true)
    entry_story_items=inventory.duplicate(true)
    balance = emeralds
    entry_balance = emeralds
