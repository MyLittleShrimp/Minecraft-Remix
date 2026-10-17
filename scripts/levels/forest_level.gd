extends "res://scripts/levels/campaign_level.gd"
@export var captain_data: CaptainData
var captain: SkeletonCaptain
var arena_active := false
var reinforcement_spawned := false
var minions: Array[RemixEnemy] = []
var intro_left := 0.0
var pending_summons: Array[Dictionary] = []

func configure_stage() -> void:
    super.configure_stage()
    stage_id = "M3A"
    stage_version = "0.2.0-crossbow.1"
    window_label = "M4-C.1 Crossbow Arsenal"
    hud_title = "林地遗迹 · 首关与骷髅队长"
    short_stage = "M3-ULTIMATE"
    course_width = ForestCourse.WIDTH
    exit_x = 11008
    finished_title = "林地遗迹，通关！"
    toast = "从安全营地出发，穿过林地遗迹，击败骷髅队长。"
    toast_left = 8

func wildlife_specs() -> Array[Dictionary]: return WildlifeContent.specs("forest_ruins")

func enemy_specs() -> Array[Dictionary]:
    return [
        {"id":&"path_zombie_a","data":zombie_data,"x":1500},
        {"id":&"path_zombie_b","data":zombie_data,"x":2110},
        {"id":&"bridge_archer_a","data":skeleton_data,"x":4224},
        {"id":&"bridge_archer_b","data":skeleton_data,"x":4656},
        {"id":&"court_creeper","data":creeper_data,"x":5488},
        {"id":&"hall_zombie_a","data":zombie_data,"x":6560},
        {"id":&"hall_archer","data":skeleton_data,"x":6816},
        {"id":&"hall_creeper","data":creeper_data,"x":7104},
        {"id":&"hall_zombie_b","data":zombie_data,"x":7648},
        {"id":&"platform_archer","data":skeleton_data,"x":2872,"y":176},
        {"id":&"path_spider","data":SPIDER_DATA,"x":2320},
        {"id":&"ruin_spider","data":SPIDER_DATA,"x":6144},
        {"id":&"trail_zombie_a","data":zombie_data,"x":7984},
        {"id":&"trail_spider_a","data":SPIDER_DATA,"x":8248},
        {"id":&"trail_zombie_b","data":zombie_data,"x":8512},
        {"id":&"trail_spider_b","data":SPIDER_DATA,"x":8736},
        {"id":&"skeleton_captain","data":captain_data,"x":10024,"captain":true}
    ]

func create_enemy(spec: Dictionary) -> RemixEnemy:
    if spec.get("captain",false):
        captain = SkeletonCaptain.new()
        captain.arena_left = ForestCourse.ARENA_LEFT
        captain.arena_right = ForestCourse.ARENA_RIGHT
        captain.shift_goal = ForestCourse.ARENA_LEFT+208
        return captain
    if spec.data.kind==EnemyData.Kind.SPIDER: return SpiderEnemy.new()
    return super.create_enemy(spec)

func enemy_id(index: int) -> StringName:
    return enemy_specs()[index].id

func checkpoint_specs() -> Array[Dictionary]:
    return [
        {"id":&"ruins_start","label":"营地入口","x":96.0,"y":288.0,"heals":false},
        {"id":&"ruins_camp_a","label":"断桥路标","x":4800.0,"y":288.0,"heals":false},
        {"id":&"ruins_camp_b","label":"队长前哨","x":8832.0,"y":288.0,"heals":false}
    ]

func checkpoint_requirements(index: int) -> Array:
    return [0,1,2,3,9,10] if index==1 else range(16)

func block_specs() -> Array[Dictionary]:
    return [
        {"id":&"camp_strength","x":256,"data":mushroom_data},
        {"id":&"camp_gem_a","x":896,"data":emerald_data},
        {"id":&"camp_gem_b","x":928,"data":emerald_data},
        {"id":&"platform_strength","x":2496,"data":mushroom_data},
        {"id":&"platform_apple","x":3248,"data":apple_data},
        {"id":&"court_strength","x":5184,"data":mushroom_data},
        {"id":&"hall_apple","x":6336,"data":apple_data},
        {"id":&"captain_strength","x":9096,"data":mushroom_data},
        {"id":&"platform_bread","x":2864,"y":96,"data":BREAD_DATA},
        {"id":&"hall_bread","x":7056,"y":144,"data":BREAD_DATA},
        {"id":&"captain_apple","x":9152,"data":apple_data}
    ] + AdventureRewards.blocks("forest_ruins")

func fragile_specs() -> Array[Dictionary]:
    return [{"id":&"court_seal","at":Vector2(5664,208),"loot":false},
        {"id":&"court_loot","at":Vector2(6024,208),"loot":true}] + AdventureRewards.chests("forest_ruins")

func _place_fixed_pickups() -> void:
    _spawn_identified(emerald_data,Vector2(2848,160),1,run_id,&"ruins_platform_gem")
    _spawn_identified(cache_data,Vector2(5752,212),1,run_id,&"ruins_cache")

func _physics_process(delta: float) -> void:
    if defeated or completed or course_paused: return
    if intro_left>0:
        intro_left=maxf(0,intro_left-delta)
        play_seconds+=delta
        if intro_left<=0:
            player.controls_locked=false
            equipment.suspend_input()
            captain.activate()
            toast="队长战：躲开金色箭道，抓住恢复窗口反击。"
            toast_left=5
        return
    if not arena_active and captain.health.current>0:
        course.entrance.set_closed(checkpoint_index<2)
        if checkpoint_index==2 and player.position.x>=ForestCourse.ARENA_LEFT+48 and player.is_on_floor():
            arena_active=true
            intro_left=1.4
            player.controls_locked=true
            player.velocity=Vector2.ZERO
            player.clear_jump_memory()
            equipment.suspend_input()
            clear_projectiles()
            course.entrance.set_closed(true)
            course.exit_gate.set_closed(true)
            camera.set_region_smooth(ForestCourse.ARENA_LEFT,ForestCourse.ARENA_RIGHT,1.2)
            print("ACTION_INTRO started=true")
            return
    _tick_summons(delta)
    super._physics_process(delta)
func _request_reinforcement(_at: Vector2) -> void:
    if reinforcement_spawned or not arena_active or captain.health.current<=0 or defeated: return
    reinforcement_spawned=true
    var candidates: Array[float] = [9360.0,9472.0,9560.0,9776.0,9888.0,10000.0,10096.0]
    candidates.sort_custom(func(a: float,b: float) -> bool: return absf(a-player.position.x)<absf(b-player.position.x))
    for x in candidates:
        if absf(x-player.position.x)<100: continue
        pending_summons.append({"at":Vector2(x,288),"left":0.75+pending_summons.size()*0.22,"epoch":run_id})
        if pending_summons.size()==3: break
    print("ACTION_SUMMON_WARNING count=%d" % pending_summons.size())

func _tick_summons(delta: float) -> void:
    if captain.health.current<=0 or not arena_active:
        pending_summons.clear()
        return
    for record in pending_summons.duplicate():
        record.left-=delta
        if record.left<=0:
            pending_summons.erase(record)
            _spawn_reinforcement.call_deferred(record.at,record.epoch)

func _spawn_reinforcement(at: Vector2, epoch: int) -> void:
    if epoch!=run_id or not arena_active or captain.health.current<=0 or defeated: return
    minions=minions.filter(func(e: RemixEnemy) -> bool: return is_instance_valid(e))
    if minions.size()>=3: return
    var minion := RemixEnemy.new()
    minion.data=zombie_data.duplicate()
    minion.data.awareness=380
    minion.data.patrol_radius=180
    minion.ui_font=ui_font
    minion.position=at
    minion.target=player
    minion.view_camera=camera
    $World.add_child(minion)
    # Brief emergence protection for the player walking over a warned spawn.
    minion.hitstun=0.35
    minions.append(minion)
    minion.health.damaged.connect(func(_event: DamageEvent) -> void: sound.play_effect(&"hit"))
    print("M3A_REINFORCEMENT count=%d" % minions.size())

func _clear_minions() -> void:
    pending_summons.clear()
    for minion in minions:
        if is_instance_valid(minion):
            minion.set_physics_process(false)
            minion.receiver.set_deferred("collision_layer",0)
            minion.queue_free()
    minions.clear()

func _enemy_loot(enemy: RemixEnemy) -> void:
    if enemy==captain:
        arena_active = false
        _clear_minions()
        clear_projectiles()
        course.entrance.set_closed(false)
        course.exit_gate.set_closed(false)
        camera.set_region_smooth(0,-1,0.6)
        _queue_drop(trophy_data,Vector2(10488,276),1,&"captain_trophy")
        toast = "骷髅队长已击败！领取 +5 战利品，前往传送门。"
        toast_left = 6
        print("M3A_CAPTAIN_DEFEATED reward=queued")
    elif enemy.data.kind!=EnemyData.Kind.SPIDER:
        super._enemy_loot(enemy)

func _reset_arena() -> void:
    intro_left=0
    player.controls_locked=false
    arena_active = false
    reinforcement_spawned = false
    _clear_minions()
    course.entrance.set_closed(checkpoint_index<2)
    course.exit_gate.set_closed(captain.health.current>0)
    camera.set_region(0)

func restore_checkpoint() -> void:
    if not defeated or snapshot==null: return
    _clear_minions()
    super.restore_checkpoint()
    _reset_arena()

func restart_course() -> void:
    _clear_minions()
    super.restart_course()
    _reset_arena()

func check_environment() -> void:
    if defeated or completed or course_paused or intro_left>0: return
    var body := Rect2(player.position+Vector2(-9,-44),Vector2(18,44))
    for fire in ForestCourse.FIRES:
        if body.intersects(fire):
            var direction := -1.0 if player.position.x<fire.get_center().x else 1.0
            health.queue_damage(DamageEvent.create(course,0,2,Vector2(direction*100,-100)))
    if player.position.y<=460: return
    var safe := Vector2(3344,288) if player.position.x<3712 else (Vector2(3824,288) if player.position.x<5000 else Vector2(7280,288))
    var fall := DamageEvent.create(course,0,4)
    fall.bypass_invulnerability = true
    fall.protection_override = 1.0
    health.queue_damage(fall)
    equipment.suspend_input()
    clear_projectiles()
    player.reset_at(safe)
    camera.reset_to_target()

func status_hint() -> String:
    if not is_instance_valid(items): return ""
    var section := 0
    for i in ForestCourse.SEGMENTS.size():
        if player.position.x>=ForestCourse.SEGMENTS[i].x: section=i
    return "%02d %s · 路标 %d/2 | 绿宝石 %d + 待结算 %d | 力量 %s" % [section+1,ForestCourse.SEGMENTS[section].name,checkpoint_index,banked_emeralds,items.emeralds-banked_emeralds,"%.1fs" % items.strength_left if items.strength_left>0 else "无"]

func setup_content() -> void:
    super.setup_content()
    captain.reinforcement_requested.connect(_request_reinforcement)
    captain.phase_changed.connect(func(_phase: int) -> void:
        toast="队长半血换边！留意援兵，重新寻找掩体。"
        toast_left=4)

func segments() -> Array[Dictionary]:
    return ForestCourse.SEGMENTS

func level_title() -> String:
    return "01 / 林地遗迹"

func next_level_path() -> String:
    return "res://scenes/levels/spiderwood_level.tscn"

func fixed_pickup_specs() -> Array[Dictionary]:
    return [{"id":&"ruins_platform_gem","data":emerald_data,"at":Vector2(2848,160)},
        {"id":&"ruins_cache","data":cache_data,"at":Vector2(5752,212)}]
