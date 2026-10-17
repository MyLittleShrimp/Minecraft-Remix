extends "res://scripts/levels/campaign_level.gd"
const VINDICATOR_DATA=preload("res://resources/enemies/vindicator.tres")
var arena_active:=false
var intro_left:=0.0
var ravager: RavagerEnemy
var encounter: MineBossEncounter

func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4G2"
    stage_version=ProjectSettings.get_setting("application/config/version")
    window_label="M4-G.4 Ravager TNT Resupply"
    hud_title="废弃矿道 · 炸出一条路"
    short_stage="M4-G.4"
    course_width=MineCourse.WIDTH
    exit_x=10912
    finished_title="废弃矿道，通关！"
    toast="深入矿道：卫道士抬斧后会锁定方向，退开重击，再找空隙反击。"
    toast_left=7

func enemy_specs() -> Array[Dictionary]:
    return [
        {"id":&"mine_zombie_a","data":zombie_data,"x":620},
        {"id":&"mine_vindicator_a","data":VINDICATOR_DATA,"x":1010},
        {"id":&"mine_archer_a","data":skeleton_data,"x":1390},
        {"id":&"mine_spider_a","data":SPIDER_DATA,"x":1640},
        {"id":&"mine_creeper_a","data":creeper_data,"x":2260},
        {"id":&"mine_vindicator_b","data":VINDICATOR_DATA,"x":3080},
        {"id":&"mine_zombie_b","data":zombie_data,"x":3400},
        {"id":&"mine_archer_b","data":skeleton_data,"x":3730},
        {"id":&"mine_spider_b","data":SPIDER_DATA,"x":4840},
        {"id":&"mine_vindicator_c","data":VINDICATOR_DATA,"x":5190},
        {"id":&"mine_archer_c","data":skeleton_data,"x":5960},
        {"id":&"mine_creeper_b","data":creeper_data,"x":6260},
        {"id":&"mine_vindicator_d","data":VINDICATOR_DATA,"x":6610},
        {"id":&"mine_zombie_c","data":zombie_data,"x":6970},
        {"id":&"mine_archer_d","data":skeleton_data,"x":8610},
        {"id":&"mine_ravager","data":preload("res://resources/enemies/ravager.tres"),"x":10256,"no_loot":true}
    ]
func create_enemy(spec: Dictionary) -> RemixEnemy:
    if spec.get("id")==&"mine_ravager":
        ravager=RavagerEnemy.new()
        ravager.arena_left=MineCourse.ARENA_LEFT+56
        ravager.arena_right=MineCourse.ARENA_RIGHT-56
        return ravager
    if spec.data.kind==EnemyData.Kind.VINDICATOR: return VindicatorEnemy.new()
    if spec.data.kind==EnemyData.Kind.SPIDER: return SpiderEnemy.new()
    return super.create_enemy(spec)
func enemy_id(index: int) -> StringName: return enemy_specs()[index].id
func checkpoint_specs() -> Array[Dictionary]:
    return [{"id":&"mine_start","label":"矿道入口","x":96.0,"y":288.0,"heals":false},
        {"id":&"mine_camp_a","label":"爆破后哨","x":2688.0,"y":288.0,"heals":false},
        {"id":&"mine_camp_b","label":"深矿路标","x":5568.0,"y":288.0,"heals":false},
        {"id":&"mine_transport_entry","label":"搬运室路标","x":7360.0,"y":288.0,"heals":false},
        {"id":&"mine_boss_camp","label":"裂岩前哨","x":9440.0,"y":288.0,"heals":false}]
func checkpoint_requirements(index: int) -> Array: return range(5) if index==1 else (range(10) if index==2 else (range(14) if index==3 else range(15)))
func armory_positions() -> Array[float]: return [160.0,2752.0,5632.0,9504.0]
func block_specs() -> Array[Dictionary]:
    return [{"id":&"mine_strength_a","x":352,"data":mushroom_data},
        {"id":&"mine_gem_a","x":224,"data":emerald_data},
        {"id":&"mine_gem_b","x":256,"data":emerald_data},
        {"id":&"mine_apple_a","x":1190,"data":apple_data},
        {"id":&"mine_bread_a","x":2464,"y":144,"data":BREAD_DATA},
        {"id":&"mine_strength_b","x":2848,"data":mushroom_data},
        {"id":&"mine_apple_b","x":3590,"data":apple_data},
        {"id":&"mine_bread_b","x":3976,"y":144,"data":BREAD_DATA},
        {"id":&"mine_gem_c","x":4710,"data":emerald_data},
        {"id":&"mine_gem_d","x":4742,"data":emerald_data},
        {"id":&"mine_apple_c","x":5700,"data":apple_data},
        {"id":&"mine_strength_c","x":5760,"data":mushroom_data},
        {"id":&"mine_bread_c","x":6880,"y":144,"data":BREAD_DATA},
        {"id":&"mine_apple_d","x":7080,"data":apple_data},
        {"id":&"mine_boss_apple","x":9480,"data":apple_data},
        {"id":&"mine_boss_bread","x":9600,"y":144,"data":BREAD_DATA}] + AdventureRewards.blocks("abandoned_mine")
func fragile_specs() -> Array[Dictionary]:
    return [{"id":&"mine_cache_seal","at":Vector2(5016,208),"loot":true,"wood":true}] + AdventureRewards.chests("abandoned_mine")
func fixed_pickup_specs() -> Array[Dictionary]:
    return [{"id":&"mine_high_cache","data":cache_data,"at":Vector2(2544,207)},
        {"id":&"mine_exit_cache","data":cache_data,"at":Vector2(9248,270)}]
func _place_fixed_pickups() -> void:
    for spec in fixed_pickup_specs(): _spawn_identified(spec.data,spec.at,1,run_id,spec.id)
func emerald_budget() -> int: return 28 # 13 enemies + 4 boxes + 1 brick + two 5-gem caches.
func mechanism_ids() -> Array[String]: return ["mine_wall_a","mine_exit_wall"]
func mechanism_requirements(index: int) -> Array[String]:
    if index==0: return []
    if index==4: return ["mine_wall_a","mine_exit_wall"]
    return ["mine_wall_a"]
func completion_mechanisms() -> Array[String]: return mechanism_ids()
func segments() -> Array[Dictionary]: return MineCourse.MINE_SEGMENTS
func level_title() -> String: return "03 / 废弃矿道"
func _activate_checkpoint(index: int) -> void:
    for id in mechanism_requirements(index):
        if not course.mechanism_state().get(id,false): return
    super._activate_checkpoint(index)

func _physics_process(delta: float) -> void:
    if defeated or completed or course_paused or transitioning: return
    if is_instance_valid(encounter) and encounter.tick(delta): return
    if player.position.x>=exit_x and not course.mechanism_state().get("mine_exit_wall",false):
        toast="先启动出口引爆杆，炸开封口石墙。"
        toast_left=2
        return
    super._physics_process(delta)

func nearby_tnt() -> MineTNT:
    if defeated or completed or transitioning or course_paused or player.controls_locked or not player.is_on_floor(): return null
    if is_instance_valid(input_panel) and input_panel.visible: return null
    if is_instance_valid(loadout_panel) and loadout_panel.visible: return null
    for bomb in course.bombs:
        if bomb is TNTTransportRoom:
            if bomb.can_interact(): return bomb
            continue
        if not bomb.active and absf(player.position.x-bomb.lever_x)<=48 and absf(player.position.y-288)<8: return bomb
    return null
func _unhandled_input(event: InputEvent) -> void:
    if is_instance_valid(encounter) and encounter.handle_input(event):
        get_viewport().set_input_as_handled()
        return
    var bomb:=nearby_tnt()
    if bomb!=null:
        var keyboard: bool=event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_E and not ControlSettings.gamepad_active()
        var pad: bool=(event is InputEventJoypadButton or event is InputEventJoypadMotion) and ControlSettings.event_pressed(event,"aim_up")
        if keyboard or pad:
            bomb.interact()
            get_viewport().set_input_as_handled()
            return
    super._unhandled_input(event)
func restart_course() -> void:
    if is_instance_valid(encounter): encounter.clear()
    course.restore_mechanisms({})
    super.restart_course()
    if is_instance_valid(encounter): encounter.reset_encounter(true)
func check_environment() -> void:
    if defeated or completed or course_paused or player.position.y<=460: return
    var safe:=Vector2(4000,288)
    if player.position.x>=4450: safe=Vector2(4656,288)
    if player.position.x>=7300:
        safe=Vector2(7360,288)
        course.bombs[1].recover_crate()
    var fall:=DamageEvent.create(course,0,4)
    fall.bypass_invulnerability=true
    fall.protection_override=1.0
    health.queue_damage(fall)
    equipment.suspend_input()
    clear_projectiles()
    player.reset_at(safe)
    camera.reset_to_target()
func panel_title() -> String:
    return "倒下了，再试一次" if defeated else (finished_title if completed else "矿道暂停")

func can_reset_transport() -> bool:
    return checkpoint_index==3 and not arena_active and not defeated and not completed and not transitioning

func reset_transport() -> void:
    if not can_reset_transport(): return
    var hp: int=health.current
    var food: float=hunger.value
    defeated=true
    restore_checkpoint()
    health.current=mini(hp,snapshot.player_health)
    hunger.restore(minf(food,snapshot.player_food))
    toast="搬运室已重置 · 本房间收益回滚，生命与饱食不会增加。"
    toast_left=5
func panel_detail() -> String:
    if completed: return "余额与配装保留 · 下一关：潮汐遗迹 · 入口解锁三叉戟"
    if can_reset_transport(): return "本房回滚"
    return super.panel_detail()

func setup_content() -> void:
    super.setup_content()
    encounter=MineBossEncounter.new()
    encounter.level=self
    $World.add_child(encounter)
    encounter.reset_encounter(true)
    ravager.phase_changed.connect(encounter.phase_changed)

func boss_actor() -> RemixEnemy: return ravager
func boss_name() -> String: return "裂岩劫掠兽"
func boss_intro_title() -> String: return "裂岩采掘厅 · 铁闸落下"

func _enemy_loot(enemy: RemixEnemy) -> void:
    if enemy==ravager:
        if is_instance_valid(encounter): encounter.victory()
        return
    super._enemy_loot(enemy)

func restore_checkpoint() -> void:
    if not defeated or snapshot==null: return
    if is_instance_valid(encounter): encounter.clear()
    super.restore_checkpoint()
    if is_instance_valid(encounter): encounter.reset_encounter(false)

func _on_death() -> void:
    if is_instance_valid(encounter): encounter.clear()
    super._on_death()

func next_level_path() -> String: return CampaignCatalog.scene_path("tidal_ruins")

func wildlife_specs() -> Array[Dictionary]: return WildlifeContent.specs("abandoned_mine")
