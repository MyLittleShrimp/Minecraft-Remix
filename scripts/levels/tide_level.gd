extends "res://scripts/levels/campaign_level.gd"
const DROWNED=preload("res://resources/enemies/drowned.tres")
const GUARDIAN=preload("res://resources/enemies/elder_guardian.tres")
var guardian: ElderGuardian
var encounter: TideBossEncounter
var arena_active:=false
var intro_left:=0.0
var sentries_active:=false
var last_hurt_label:=""
var last_hurt_left:=0.0
var ending: CampaignChapterRecap
func has_campaign_ending() -> bool:
    return completed and is_instance_valid(ending) and ending.active
func configure_stage() -> void:
    GuardianArt.prepare()
    super.configure_stage()
    stage_id="M4J2"
    stage_version=ProjectSettings.get_setting("application/config/version")
    window_label="M4-L.1 Chapter Recap"
    hud_title="潮汐遗迹 · 唤雷破阵"
    short_stage="M4-J.2"
    course_width=TideCourse.WIDTH
    exit_x=8672
    finished_title="潮汐遗迹，通关！"
    toast="三叉戟已在入口武器架解锁 · E 换装，短按突刺，蓄力松手投掷。"
    toast_left=8
func enemy_specs() -> Array[Dictionary]:
    var specs: Array[Dictionary]=[]
    var kinds: Array[EnemyData]=[zombie_data,DROWNED,skeleton_data,creeper_data,SPIDER_DATA,DROWNED,skeleton_data,zombie_data,SPIDER_DATA,DROWNED,DROWNED,zombie_data,creeper_data,SPIDER_DATA,SPIDER_DATA,SPIDER_DATA,DROWNED,skeleton_data]
    var positions: Array[int]=[650,1050,1490,1810,2160,2780,3150,3460,3900,4330,4900,5050,5630,5870,6480,6540,6610,6750]
    for i in kinds.size(): specs.append({"id":StringName("tide_enemy_%02d"%i),"data":kinds[i],"x":positions[i]})
    specs.append({"id":&"tide_guardian","data":GUARDIAN,"x":8096,"no_loot":true})
    return specs
func create_enemy(spec: Dictionary) -> RemixEnemy:
    if spec.data==GUARDIAN:
        guardian=ElderGuardian.new()
        guardian.arena_left=TideCourse.ARENA_LEFT+44
        guardian.arena_right=TideCourse.ARENA_RIGHT-44
        return guardian
    if spec.data.kind==EnemyData.Kind.DROWNED: return DrownedEnemy.new()
    if spec.data.kind==EnemyData.Kind.SPIDER: return SpiderEnemy.new()
    return super.create_enemy(spec)
func enemy_id(index: int) -> StringName: return enemy_specs()[index].id
func checkpoint_specs() -> Array[Dictionary]:
    return [{"id":&"tide_start","label":"潮岸武库","x":96.0,"y":288.0,"heals":false},
        {"id":&"tide_camp_a","label":"潮纹路标","x":2304.0,"y":288.0,"heals":false},
        {"id":&"tide_camp_b","label":"沉桥前哨","x":4608.0,"y":288.0,"heals":false},
        {"id":&"tide_camp_c","label":"雷鸣前哨","x":6144.0,"y":288.0,"heals":false},
        {"id":&"tide_boss_camp","label":"神殿前哨","x":7232.0,"y":288.0,"heals":false}]
func checkpoint_requirements(index: int) -> Array: return range(5 if index==1 else (10 if index==2 else (14 if index==3 else 18)))
func armory_positions() -> Array[float]: return [160.0,2368.0,4672.0,6208.0,7296.0]
func block_specs() -> Array[Dictionary]:
    return [{"id":&"tide_gem_a","x":224,"data":emerald_data},{"id":&"tide_gem_b","x":256,"data":emerald_data},
        {"id":&"tide_apple_a","x":1200,"data":apple_data},{"id":&"tide_bread_a","x":1336,"y":144,"data":BREAD_DATA},
        {"id":&"tide_apple_b","x":2432,"data":apple_data},{"id":&"tide_bread_b","x":3384,"y":144,"data":BREAD_DATA},
        {"id":&"tide_bread_c","x":4456,"y":144,"data":BREAD_DATA},{"id":&"tide_apple_c","x":4736,"data":apple_data},
        {"id":&"tide_bread_d","x":6072,"y":144,"data":BREAD_DATA},{"id":&"tide_apple_d","x":6236,"data":apple_data},
        {"id":&"tide_boss_apple","x":7360,"data":apple_data},{"id":&"tide_boss_bread","x":7432,"y":144,"data":BREAD_DATA}] + AdventureRewards.blocks("tidal_ruins")
func fragile_specs() -> Array[Dictionary]: return [] + AdventureRewards.chests("tidal_ruins")
func fixed_pickup_specs() -> Array[Dictionary]:
    return [{"id":&"tide_cache_a","data":cache_data,"at":Vector2(1376,205)},
        {"id":&"tide_cache_b","data":cache_data,"at":Vector2(3440,205)},
        {"id":&"tide_cache_c","data":cache_data,"at":Vector2(5952,270)}]
func _place_fixed_pickups() -> void:
    for spec in fixed_pickup_specs(): _spawn_identified(spec.data,spec.at,1,run_id,spec.id)
func emerald_budget() -> int: return 30
func mechanism_ids() -> Array[String]: return ["tide_bridge"]
func mechanism_requirements(index: int) -> Array[String]: return ["tide_bridge"] if index>=3 else []
func completion_mechanisms() -> Array[String]: return mechanism_ids()
func segments() -> Array[Dictionary]: return TideCourse.TIDE_SEGMENTS
func level_title() -> String: return "04 / 潮汐遗迹"
func boss_name() -> String: return "潮汐远古守卫者"
func boss_intro_title() -> String: return "潮汐神殿 · 独眼苏醒"
func boss_actor() -> RemixEnemy: return guardian
func _activate_checkpoint(index: int) -> void:
    for id in mechanism_requirements(index):
        if not course.mechanism_state().get(id,false): return
    super._activate_checkpoint(index)
func panel_title() -> String: return "倒下了，再试一次" if defeated else (finished_title if completed else "潮岸暂停")
func panel_detail() -> String:
    if completed: return "远古守卫者已击败 · 四关远征完成 · 余额已保存"
    return super.panel_detail()
func _unhandled_input(event: InputEvent) -> void:
    if has_campaign_ending(): return
    if not defeated and not completed and not course_paused and not transitioning and not player.controls_locked and player.is_on_floor() and absf(player.position.x-5088)<48:
        var keyboard: bool=event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_E and not ControlSettings.gamepad_active()
        var pad: bool=(event is InputEventJoypadButton or event is InputEventJoypadMotion) and ControlSettings.event_pressed(event,"aim_up")
        if keyboard or pad:
            course.bridge_target.receive_projectile(DamageEvent.create(player,1,0))
            get_viewport().set_input_as_handled()
            return
    super._unhandled_input(event)
func check_environment() -> void:
    if defeated or completed or course_paused or player.position.y<=460: return
    var safe:=Vector2(1856,288)
    if player.position.x>3000: safe=Vector2(3520,288)
    if player.position.x>4800: safe=Vector2(5088,288)
    var fall:=DamageEvent.create(course,0,4)
    fall.bypass_invulnerability=true
    fall.protection_override=1.0
    health.queue_damage(fall)
    equipment.suspend_input()
    clear_projectiles()
    player.reset_at(safe)
    camera.reset_to_target()
func restart_course() -> void:
    if is_instance_valid(ending): ending.reset()
    if is_instance_valid(encounter): encounter.clear()
    course.restore_mechanisms({})
    super.restart_course()
    _set_sentries(false)
    if is_instance_valid(encounter): encounter.reset_encounter(true)

func setup_content() -> void:
    super.setup_content()
    _set_sentries(false)
    player.z_index=1
    encounter=TideBossEncounter.new()
    encounter.level=self
    $World.add_child(encounter)
    encounter.reset_encounter(true)
    guardian.phase_changed.connect(encounter.request_guards)
    health.damaged.connect(_show_hurt_source)
    ending=CampaignChapterRecap.new()
    ending.level=self
    $UI.add_child(ending)
    $UI.move_child(input_panel,-1)
    if completed: ending.begin(true)

func _set_sentries(active: bool) -> void:
    sentries_active=active
    for i in range(14,18):
        var enemy: RemixEnemy=targets[i]
        enemy.visible=active
        enemy.process_mode=Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
        enemy.receiver.set_deferred("collision_layer",16 if active and enemy.health.current>0 else 0)

func restore_checkpoint() -> void:
    if not defeated or snapshot==null: return
    if is_instance_valid(encounter): encounter.clear()
    super.restore_checkpoint()
    _set_sentries(false)
    if is_instance_valid(encounter): encounter.reset_encounter(false)

func _on_death() -> void:
    if is_instance_valid(encounter): encounter.clear()
    super._on_death()

func _enemy_loot(enemy: RemixEnemy) -> void:
    if enemy==guardian:
        encounter.victory()
        return
    super._enemy_loot(enemy)

func _show_hurt_source(event: DamageEvent) -> void:
    var label: String=event.get_meta("guardian_attack","")
    var source:=instance_from_id(event.source_id)
    if source is DrownedEnemy: label="溺尸投戟"
    elif event.get_meta("starvation",false): label="饥饿"
    if label.is_empty(): return
    last_hurt_label="受到%s -%d生命" % [label,event.amount]
    last_hurt_left=2.0

func _physics_process(delta: float) -> void:
    if defeated or completed or course_paused or transitioning: return
    if is_instance_valid(encounter) and encounter.tick(delta): return
    if not sentries_active and player.position.x>=6370:
        _set_sentries(true)
        if targets.slice(14,18).any(func(e: RemixEnemy) -> bool: return e.health.current>0):
            toast="潮汐守卫现身 · 雷霆可同时清理多个目标"
            toast_left=4
    super._physics_process(delta)
    if completed: ending.begin(false)

func next_level_path() -> String: return CampaignCatalog.scene_path("warped_border")

func wildlife_specs() -> Array[Dictionary]: return WildlifeContent.specs("tidal_ruins")
