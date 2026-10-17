extends "res://scripts/levels/campaign_level.gd"
const WITCH_DATA = preload("res://resources/enemies/witch.tres")
const QUEEN_DATA = preload("res://resources/enemies/witch_queen.tres")
const MEAT: Array[PickupData] = [preload("res://resources/items/rabbit_meat.tres"),preload("res://resources/items/mutton.tres"),preload("res://resources/items/pork.tres")]
var queen: WitchEnemy
var poison: PoisonComponent
var arena_active := false
var intro_left := 0.0
var pending_summons: Array[Dictionary] = []
var queen_guards: Array[RemixEnemy] = []
var guard_phase := 0
var summon_generation := 0

func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4B"
    stage_version="0.2.0-crossbow.1"
    window_label="M4-C.1 Crossbow Arsenal"
    hud_title="蛛影林径 · 女巫皇后"
    short_stage="M4-B"
    course_width=9472
    exit_x=9280
    finished_title="蛛影林径，通关！"
    toast="月夜林径：留意树上的蜘蛛，用弓射中靶点放下木桥。"
    toast_left=7

func enemy_specs() -> Array[Dictionary]:
    return [
        {"id":&"night_zombie_a","data":zombie_data,"x":620},
        {"id":&"tree_spider_a","data":SPIDER_DATA,"x":1120,"y":174,"ambush":true},
        {"id":&"brook_archer","data":skeleton_data,"x":1650},
        {"id":&"brook_spider","data":SPIDER_DATA,"x":1900},
        {"id":&"bank_creeper","data":creeper_data,"x":2570},
        {"id":&"tree_spider_b","data":SPIDER_DATA,"x":2880,"y":174,"ambush":true},
        {"id":&"ridge_archer","data":skeleton_data,"x":3670},
        {"id":&"ridge_spider","data":SPIDER_DATA,"x":3990},
        {"id":&"ridge_zombie","data":zombie_data,"x":4340},
        {"id":&"tree_spider_c","data":SPIDER_DATA,"x":4800,"y":166,"ambush":true},
        {"id":&"gate_creeper","data":creeper_data,"x":5080},
        {"id":&"gate_archer_a","data":skeleton_data,"x":6220},
        {"id":&"tree_spider_d","data":SPIDER_DATA,"x":6470,"y":174,"ambush":true},
        {"id":&"gate_zombie","data":zombie_data,"x":6740},
        {"id":&"gate_spider","data":SPIDER_DATA,"x":7050},
        {"id":&"gate_archer_b","data":skeleton_data,"x":7420},
        {"id":&"brook_witch","data":WITCH_DATA,"x":1380},
        {"id":&"ridge_witch","data":WITCH_DATA,"x":4240},
        {"id":&"witch_queen","data":QUEEN_DATA,"x":8752,"queen":true,"loot":trophy_data}
    ]

func create_enemy(spec: Dictionary) -> RemixEnemy:
    if spec.get("queen",false):
        queen=WitchEnemy.new()
        queen.queen=true
        return queen
    if spec.data.kind==EnemyData.Kind.WITCH: return WitchEnemy.new()
    if spec.get("ambush",false): return AmbushSpider.new()
    if spec.data.kind==EnemyData.Kind.SPIDER: return SpiderEnemy.new()
    return super.create_enemy(spec)

func enemy_id(index: int) -> StringName: return enemy_specs()[index].id
func checkpoint_specs() -> Array[Dictionary]:
    return [
        {"id":&"spider_start","label":"月夜入口","x":96.0,"y":288.0,"heals":false},
        {"id":&"spider_camp_a","label":"溪畔路标","x":3328.0,"y":288.0,"heals":false},
        {"id":&"spider_camp_b","label":"守门前哨","x":5808.0,"y":288.0,"heals":false}
    ]
func checkpoint_requirements(index: int) -> Array: return range(6)+[16] if index==1 else range(11)+[16,17]

func block_specs() -> Array[Dictionary]:
    return [
        {"id":&"night_strength","x":320,"data":mushroom_data},
        {"id":&"night_gem_a","x":800,"data":emerald_data},
        {"id":&"night_gem_b","x":832,"data":emerald_data},
        {"id":&"brook_apple","x":1456,"data":apple_data},
        {"id":&"bank_bread","x":3056,"y":144,"data":BREAD_DATA},
        {"id":&"ridge_strength","x":3488,"data":mushroom_data},
        {"id":&"ridge_apple","x":4176,"data":apple_data},
        {"id":&"canopy_bread","x":5200,"y":96,"data":BREAD_DATA},
        {"id":&"gate_apple","x":5940,"data":apple_data},
        {"id":&"gate_strength","x":5980,"data":mushroom_data},
        {"id":&"queen_apple","x":7840,"data":apple_data}
    ] + AdventureRewards.blocks("spiderwood")

func fragile_specs() -> Array[Dictionary]:
    return [{"id":&"night_cache_seal","at":Vector2(3912,208),"loot":true}] + AdventureRewards.chests("spiderwood")
func fixed_pickup_specs() -> Array[Dictionary]:
    return [{"id":&"night_canopy_gem","data":cache_data,"at":Vector2(3120,205)},
        {"id":&"night_exit_cache","data":cache_data,"at":Vector2(7776,270)}]
func _place_fixed_pickups() -> void:
    for spec in fixed_pickup_specs(): _spawn_identified(spec.data,spec.at,1,run_id,spec.id)
func emerald_budget() -> int: return 29 # Previous 22 + two witches + queen trophy 5.
func mechanism_ids() -> Array[String]: return ["brook_bridge","canopy_bridge"]
func mechanism_requirements(index: int) -> Array[String]:
    return [] if index==0 else (["brook_bridge"] if index==1 else ["brook_bridge","canopy_bridge"])
func segments() -> Array[Dictionary]: return SpiderwoodCourse.SEGMENTS
func level_title() -> String: return "02 / 蛛影林径"

func _activate_checkpoint(index: int) -> void:
    for id in mechanism_requirements(index):
        if not course.mechanism_state().get(id,false): return
    super._activate_checkpoint(index)

func _physics_process(delta: float) -> void:
    if transitioning or defeated or completed or course_paused: return
    if intro_left>0:
        intro_left=maxf(0,intro_left-delta)
        play_seconds+=delta
        if intro_left<=0:
            player.controls_locked=false
            equipment.suspend_input()
            queen.activate()
            _request_guards(1)
        return
    course.exit_gate.set_closed(queen.health.current>0)
    if not arena_active and queen.health.current>0:
        var guards_clear:=cleared_count()>=targets.size()-1
        course.entrance.set_closed(not guards_clear or checkpoint_index<2)
        if guards_clear and checkpoint_index==2 and player.position.x>=8050 and player.is_on_floor():
            arena_active=true
            intro_left=1.4
            player.controls_locked=true
            player.velocity=Vector2.ZERO
            player.clear_jump_memory()
            equipment.suspend_input()
            clear_projectiles()
            course.entrance.set_closed(true)
            camera.set_region_smooth(8000,9024,1.2)
            print("WITCH_INTRO started=true")
            return
    _tick_guards(delta)
    super._physics_process(delta)

func _request_guards(phase: int) -> void:
    if phase<=guard_phase or not arena_active or queen.health.current<=0 or defeated: return
    guard_phase=phase
    # Top up surviving guards to the new formation, never stack eight enemies.
    for kind in [EnemyData.Kind.SPIDER,EnemyData.Kind.SKELETON]:
        var wanted: int=(3 if kind==EnemyData.Kind.SPIDER else 2) if phase==2 else (2 if kind==EnemyData.Kind.SPIDER else 1)
        var count:=0
        for guard in queen_guards:
            if is_instance_valid(guard) and guard.health.current>0 and guard.data.kind==kind: count+=1
        for pending in pending_summons:
            if pending.kind==kind: count+=1
        for i in maxi(0,wanted-count):
            var candidates: Array[float]=[8120.0,8260.0,8400.0,8540.0,8680.0,8820.0,8950.0]
            candidates.sort_custom(func(a: float,b: float) -> bool: return absf(a-queen.position.x)<absf(b-queen.position.x))
            for x in candidates:
                if absf(x-player.position.x)<110: continue
                if pending_summons.any(func(p: Dictionary) -> bool: return absf(p.at.x-x)<60): continue
                if queen_guards.any(func(g: RemixEnemy) -> bool: return is_instance_valid(g) and g.health.current>0 and absf(g.position.x-x)<60): continue
                pending_summons.append({"at":Vector2(x,288),"kind":kind,"left":0.9+pending_summons.size()*0.15,"queued":false,"epoch":run_id,"generation":summon_generation})
                break
    print("QUEEN_GUARDS phase=%d pending=%d" % [phase,pending_summons.size()])

func _tick_guards(delta: float) -> void:
    if not arena_active or queen.health.current<=0: return
    for record in pending_summons:
        if record.queued: continue
        record.left-=delta
        if record.left<=0:
            record.queued=true
            _spawn_guard.call_deferred(record)

func _spawn_guard(record: Dictionary) -> void:
    pending_summons.erase(record)
    if record.epoch!=run_id or record.generation!=summon_generation or not arena_active or queen.health.current<=0 or defeated: return
    var guard: RemixEnemy=SpiderEnemy.new() if record.kind==EnemyData.Kind.SPIDER else RemixEnemy.new()
    guard.data=(SPIDER_DATA if record.kind==EnemyData.Kind.SPIDER else skeleton_data).duplicate()
    guard.data.label="蜘蛛护卫" if record.kind==EnemyData.Kind.SPIDER else "骷髅护卫"
    guard.data.awareness=380
    guard.data.patrol_radius=180
    guard.position=record.at
    guard.target=player
    guard.view_camera=camera
    guard.ui_font=ui_font
    $World.add_child(guard)
    guard.hitstun=0.35
    queen_guards.append(guard)
    guard.health.damaged.connect(func(_event: DamageEvent) -> void: sound.play_effect(&"hit"))
    guard.fired.connect(func(_arrow: ArrowProjectile) -> void: sound.play_effect(&"arrow"))
    # Guards are transient encounter actors: no loot, checkpoint or target IDs.

func _clear_guards() -> void:
    summon_generation+=1
    pending_summons.clear()
    for guard in queen_guards:
        if is_instance_valid(guard):
            guard.set_physics_process(false)
            guard.receiver.set_deferred("collision_layer",0)
            guard.queue_free()
    queen_guards.clear()

func boss_actor() -> RemixEnemy: return queen
func boss_name() -> String: return "女巫皇后"

func setup_content() -> void:
    poison=PoisonComponent.new()
    poison.name="Poison"
    player.add_child(poison)
    super.setup_content()
    queen.phase_changed.connect(func(_phase: int) -> void:
        _request_guards(2)
        toast="二阶段：护卫增援、快速三瓶！先避开落点，再找空隙反击。"
        toast_left=4)
    for enemy in targets:
        if enemy is WitchEnemy: enemy.potion_thrown.connect(func() -> void: sound.play_effect(&"arrow"))

func wildlife_specs() -> Array[Dictionary]: return WildlifeContent.specs("spiderwood")
func _enemy_loot(enemy: RemixEnemy) -> void:
    if enemy==queen:
        arena_active=false
        _clear_guards()
        clear_projectiles()
        poison.clear()
        course.entrance.set_closed(false)
        course.exit_gate.set_closed(false)
        camera.set_region_smooth(0,-1,0.6)
        _queue_drop(trophy_data,Vector2(9120,276),1,&"enemy/witch_queen")
        toast="女巫皇后已击败！领取 +5 绿宝石，前往出口。"
        toast_left=6
    else: super._enemy_loot(enemy)
func _reset_arena() -> void:
    _clear_guards()
    guard_phase=0
    intro_left=0
    arena_active=false
    player.controls_locked=false
    poison.clear()
    course.entrance.set_closed(queen.health.current>0 and cleared_count()<targets.size()-1)
    course.exit_gate.set_closed(queen.health.current>0)
    camera.set_region(0)
func restart_course() -> void:
    _clear_guards()
    course.restore_mechanisms({})
    super.restart_course()
    _reset_arena()
func restore_checkpoint() -> void:
    if not defeated or snapshot==null: return
    _clear_guards()
    super.restore_checkpoint()
    _reset_arena()
    if queen.health.current>0: queen.receiver.set_deferred("collision_layer",0)

func check_environment() -> void:
    if defeated or completed or course_paused or intro_left>0: return
    if player.position.y<=460: return
    var safe:=Vector2(1980,288)
    if player.position.x>=4200: safe=Vector2(4400,288)
    if player.position.x>=5000: safe=Vector2(5180,288)
    if arena_active: safe=Vector2(8080,288)
    var fall:=DamageEvent.create(course,0,4)
    fall.bypass_invulnerability=true
    fall.protection_override=1.0
    health.queue_damage(fall)
    equipment.suspend_input()
    clear_projectiles()
    player.reset_at(safe)
    camera.reset_to_target()

func panel_detail() -> String:
    return super.panel_detail()

func next_level_path() -> String:
    return "res://scenes/levels/mine_level.tscn"
