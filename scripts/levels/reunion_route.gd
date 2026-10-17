extends "res://scripts/levels/wither_lab.gd"
const ROUTE=preload("res://scripts/world/reunion_course.gd")
const WAVES: Array=[
    ["zombie","skeleton","creeper"],["spider","witch"],
    ["vindicator","skeleton"],["drowned","drowned"],
    ["enderman","ghast"],["wither_skeleton","blaze"],
    ["piglin_sword","piglin_axe"],["zombie","piglin_crossbow"]]
var poison: PoisonComponent
func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4W2"
    short_stage="M4-W.2"
    window_label="M4-W.2 Finale Reunion"
    hud_title="终章前奏 · 六境回响"
    course_width=7360
    exit_x=7280
    finished_title="六境回响，完成！"
    toast="八场回顾战 · 每次最多三敌 · 清场后路标只记录、不回血"
    toast_left=8
func _ready() -> void:
    FinaleJourney.reset(not campaign_mode)
    super._ready()
    if finale!=null: finale.finish_setup()
func setup_content() -> void:
    poison=PoisonComponent.new()
    poison.name="Poison"
    player.add_child(poison)
    super.setup_content()
func encounter_groups() -> Array:
    var groups: Array=[]
    var index:=0
    for wave in WAVES:
        groups.append(range(index,index+wave.size()))
        index+=wave.size()
    return groups
func encounter_hint(room: int) -> String: return ROUTE.HINTS[room]
func enemy_specs() -> Array[Dictionary]:
    var specs: Array[Dictionary]=[]
    for room in WAVES.size():
        var bounds: Vector2=ROUTE.ROOMS[room]
        for i in WAVES[room].size():
            var id: String=WAVES[room][i]
            var y:=GhastEnemy.HIGH_Y if id=="ghast" else (BlazeEnemy.HIGH_Y if id=="blaze" else 288.0)
            specs.append({"data":load("res://resources/enemies/"+id+".tres"),"x":bounds.x+280+i*136,"y":y,"left":bounds.x,"right":bounds.y})
    for i in specs.size():
        specs[i]["id"]=enemy_id(i)
        specs[i]["no_loot"]=specs[i].data.kind==EnemyData.Kind.SPIDER
    return specs
func create_enemy(spec: Dictionary) -> RemixEnemy:
    var bounds:=Vector2(spec.left,spec.right)
    match spec.data.kind:
        EnemyData.Kind.SPIDER: return SpiderEnemy.new()
        EnemyData.Kind.WITCH: return WitchEnemy.new()
        EnemyData.Kind.VINDICATOR: return VindicatorEnemy.new()
        EnemyData.Kind.DROWNED: return DrownedEnemy.new()
        EnemyData.Kind.ENDERMAN:
            var actor:=EndermanEnemy.new()
            actor.guard_mode=true
            actor.encounter_bounds=bounds+Vector2(18,-18)
            return actor
        EnemyData.Kind.GHAST:
            var actor:=GhastEnemy.new()
            actor.arena_bounds=bounds
            return actor
        EnemyData.Kind.BLAZE:
            var actor:=BlazeEnemy.new()
            actor.arena_bounds=bounds
            return actor
    return super.create_enemy(spec)
func _set_enemy_active(enemy: RemixEnemy,value: bool) -> void:
    enemy.set_physics_process(value)
    if enemy is EndermanEnemy:
        if value: enemy.activate_guard()
        else:
            enemy.encounter_enabled=false
            enemy.strike_pending=false
            enemy.receiver.set_deferred("collision_layer",0)
    elif enemy is GhastEnemy or enemy is BlazeEnemy:
        if value: enemy.activate()
        else:
            enemy.active=false
            enemy.pending_shot=false
            if enemy is GhastEnemy: enemy.retire_ball()
            else: enemy.clear_balls()
            enemy.receiver.set_deferred("collision_layer",0)
    else:
        if enemy is WitchEnemy:
            enemy.active=value
            enemy.throw_due=false
        if enemy is DrownedEnemy: enemy.throw_pending=false
        super._set_enemy_active(enemy,value)
func enemy_id(index: int) -> StringName: return StringName("reunion_%d"%index)
func checkpoint_specs() -> Array[Dictionary]:
    var specs: Array[Dictionary]=[{"id":&"reunion_start","label":"回响武库","x":96.0,"heals":false}]
    for room in ROUTE.ROOMS.size():
        specs.append({"id":StringName("reunion_camp_%d"%room),"label":ROUTE.TITLES[room]+"路标","x":ROUTE.ROOMS[room].y+80,"heals":false})
    return specs
func checkpoint_requirements(index: int) -> Array:
    var count:=0
    for i in index: count+=WAVES[i].size()
    return range(count)
func can_activate_checkpoint(index: int) -> bool:
    if not super.can_activate_checkpoint(index): return false
    for i in checkpoint_requirements(index):
        if targets[i].health.current>0: return false
    return true
func _physics_process(delta: float) -> void:
    if course_paused or defeated or completed or transitioning: return
    while checkpoint_index<8:
        var next:=checkpoint_index+1
        if player.position.x<checkpoint_specs()[next].x or not can_activate_checkpoint(next): break
        _activate_checkpoint(next)
    super._physics_process(delta)
func block_specs() -> Array[Dictionary]:
    var specs: Array[Dictionary]=[]
    for room in 8:
        specs.append({"id":StringName("reunion_food_%d"%room),"x":ROUTE.ROOMS[room].y+152,"y":208,"data":BREAD_DATA if room%2==0 else apple_data})
    return specs + AdventureRewards.blocks("reunion")
func armory_positions() -> Array[float]: return [160.0,1040.0,1904.0,2768.0,3632.0,4496.0,5360.0,6224.0,7088.0]
func segments() -> Array[Dictionary]:
    var result: Array[Dictionary]=[{"x":0,"name":"回响武库"}]
    for i in 8: result.append({"x":ROUTE.ROOMS[i].x,"name":ROUTE.TITLES[i]})
    return result
func restart_course() -> void:
    if finale!=null:
        finale.restart_segment()
        return
    FinaleJourney.reset(true)
    poison.clear()
    super.restart_course()
func restore_checkpoint() -> void:
    if not defeated: return
    poison.clear()
    super.restore_checkpoint()
func next_level_path() -> String: return "res://scenes/levels/portal_trial.tscn"
func next_level_label() -> String: return "继续终章 · 三眼之门"
func advance_level() -> void:
    if finale!=null: finale.advance()
    else: FinaleJourney.advance(self,next_level_path())
func level_title() -> String: return "终章 · 六境回响"
func result_hint() -> String: return "12类旧敌 · 八场回顾 · 接续三眼之门与末影龙"
func panel_detail() -> String: return "正式终章 · 路标自动保存 · 血食与配装沿用至下一段" if campaign_mode else "血量、饱食、宝石和装备带入下一段 · 仅本次试玩有效"

func wildlife_specs() -> Array[Dictionary]: return WildlifeContent.specs("reunion")
func fixed_pickup_specs() -> Array[Dictionary]: return ExplorationRewards.specs("reunion")
func _place_fixed_pickups() -> void:
    for spec in fixed_pickup_specs(): _spawn_identified(spec.data,spec.at,1,run_id,spec.id)

func fragile_specs() -> Array[Dictionary]: return AdventureRewards.chests("reunion")
