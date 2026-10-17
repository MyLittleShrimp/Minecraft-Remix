extends "res://scripts/levels/campaign_level.gd"
## Shared fortress encounters; trials stay isolated from campaign saves.
@export var campaign_mode := false
var wither: WitherComponent
var arena_active := false
var intro_left := 0.0
var active_room := -1
var encounters_enabled := true
const GROUPS := [[0],[1],[2,3],[4],[5],[6],[7,8]]
const ROOM_HINTS := ["凋零：命中后每秒扣1生命，共3秒；重复命中只刷新","越过长剑到背后 · 等收招再打","先分开敌人 · 避免被长剑夹击","金剑蛮兵：追击快 · 抢先出手或退开反击","金斧蛮兵：重劈有霸体 · 诱出重击再反击","连弩蛮兵：两次瞄准两支箭 · 跳躲后趁装填进攻","剑弩夹击：留意弩手预警 · 分开处理"]
func encounter_groups() -> Array: return GROUPS
func encounter_hint(room: int) -> String: return ROOM_HINTS[room]
func _ready() -> void:
    if not campaign_mode:
        saves.enabled=false
        saves.pending_resume.clear()
    wither=WitherComponent.new()
    wither.name="Wither"
    player.add_child(wither)
    super._ready()
    player.z_index=2
    practice_target.position.x=232
    practice_target.label="试刀木靶"
    _reset_encounters()
func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4R2"
    stage_version=ProjectSettings.get_setting("application/config/version")
    window_label="M4-R.2 Fortress Piglin Trial"
    hud_title="堡垒试炼 · 骸骨与猪灵"
    short_stage="M4-R.2"
    course_width=5248
    exit_x=5120
    finished_title="堡垒前哨试炼完成"
    toast="长剑蓄力时退开 / 跳到背后 · 收招后反击"
    toast_left=9
func _enter_campaign_level() -> void:
    if campaign_mode:
        super._enter_campaign_level()
        return
    wallet.reset_to_entry(40)
    hunger.restore(20,true)
    campaign_settled=true
    equipment.configure_loadout(["netherite_sword","bow"])
    equipment.slot=0
func persist_checkpoint() -> void:
    if campaign_mode: super.persist_checkpoint()
func create_enemy(spec: Dictionary) -> RemixEnemy:
    if spec.data.kind==EnemyData.Kind.PIGLIN_BRUTE:
        var piglin:=PiglinBrute.new()
        piglin.active=false
        piglin.encounter_bounds=Vector2(spec.left+18,spec.right-18)
        return piglin
    if spec.data.kind!=EnemyData.Kind.WITHER_SKELETON: return RemixEnemy.new()
    var enemy:=WitherSkeleton.new()
    enemy.active=false
    enemy.encounter_bounds=Vector2(spec.left+18,spec.right-18)
    return enemy
func enemy_specs() -> Array[Dictionary]:
    var data:=preload("res://resources/enemies/wither_skeleton.tres")
    return [{"data":data,"x":608,"left":320,"right":832},
        {"data":data,"x":1248,"left":960,"right":1472},
        {"data":data,"x":1912,"left":1600,"right":2240},
        {"data":zombie_data,"x":2120,"left":1600,"right":2240},
        {"data":preload("res://resources/enemies/piglin_sword.tres"),"x":2592,"left":2336,"right":2848},
        {"data":preload("res://resources/enemies/piglin_axe.tres"),"x":3232,"left":2976,"right":3488},
        {"data":preload("res://resources/enemies/piglin_crossbow.tres"),"x":4000,"left":3616,"right":4256},
        {"data":preload("res://resources/enemies/piglin_sword.tres"),"x":4672,"left":4384,"right":5024},
        {"data":preload("res://resources/enemies/piglin_crossbow.tres"),"x":4896,"left":4384,"right":5024}]
func enemy_id(index: int) -> StringName: return StringName("trial_wither_%d"%index)
func checkpoint_specs() -> Array[Dictionary]:
    return [{"id":&"wither_start","label":"前哨武库","x":96.0,"heals":true},
        {"id":&"wither_camp","label":"试刀路标","x":880.0,"heals":false},
        {"id":&"piglin_camp","label":"猪灵武库","x":2288.0,"heals":false},
        {"id":&"piglin_crossbow_camp","label":"连弩路标","x":3552.0,"heals":false}]
func checkpoint_requirements(index: int) -> Array:
    if index==1: return [0]
    if index==2: return [0,1,2,3]
    if index==3: return [0,1,2,3,4,5]
    return []
func block_specs() -> Array[Dictionary]:
    return [{"id":&"wither_apple","x":900,"y":208,"data":apple_data},
        {"id":&"wither_bread","x":1536,"y":208,"data":BREAD_DATA},
        {"id":&"piglin_apple","x":2296,"y":208,"data":apple_data},
        {"id":&"piglin_bread","x":2912,"y":208,"data":BREAD_DATA},
        {"id":&"piglin_last_apple","x":4320,"y":208,"data":apple_data}]
func fragile_specs() -> Array[Dictionary]: return []
func _place_fixed_pickups() -> void: pass
func _enemy_loot(enemy: RemixEnemy) -> void:
    # Authored drops and the save catalog share the same opt-in. Older isolated
    # combat labs keep their zero-reward budget; summoned guards are not authored.
    for spec in enemy_specs():
        if spec.get("id", &"")==enemy.get_meta("object_id", &"missing"):
            if _has_emerald_reward(spec): super._enemy_loot(enemy)
            return

func _has_emerald_reward(spec: Dictionary) -> bool:
    return not spec.get("no_loot",true) and spec.data.kind!=EnemyData.Kind.SPIDER
func _set_enemy_active(enemy: RemixEnemy,value: bool) -> void:
    if enemy is WitherSkeleton or enemy is PiglinBrute: enemy.set_active(value)
    else:
        enemy.set_physics_process(value)
        enemy.receiver.set_deferred("collision_layer",16 if value and enemy.health.current>0 else 0)
        enemy.velocity=Vector2.ZERO
func _physics_process(delta: float) -> void:
    if course_paused or defeated or completed: return
    if encounters_enabled:
        if active_room>=0 and _room_cleared(active_room):
            course.release_room(active_room)
            active_room=-1
            toast="铁门已开启 · 继续向右；路标不回血"
            toast_left=3
        if active_room<0:
            for room in encounter_groups().size():
                if _room_cleared(room): continue
                if player.position.x>=course.ROOMS[room].x+32 and player.is_on_floor():
                    active_room=room
                    course.start_room(room)
                    for index in encounter_groups()[room]: _set_enemy_active(targets[index],true)
                    show_guide(encounter_hint(room))
                break
    super._physics_process(delta)
func _room_cleared(index: int) -> bool:
    for target_index in encounter_groups()[index]:
        if targets[target_index].health.current>0: return false
    return true
func _reset_encounters() -> void:
    active_room=-1
    course.reset_rooms()
    for enemy in targets: _set_enemy_active(enemy,false)
    for room in encounter_groups().size():
        if _room_cleared(room): course.release_room(room)
func restart_course() -> void:
    wither.clear()
    super.restart_course()
    _reset_encounters()
func restore_checkpoint() -> void:
    if not defeated: return
    wither.clear()
    super.restore_checkpoint()
    _reset_encounters()
func _on_damage(event: DamageEvent) -> void:
    super._on_damage(event)
    if event.get_meta("wither_tick",false): toast="凋零 -1 · 倒计时结束后停止扣血"
    elif event.get_meta("wither_impact",false): toast="被长剑命中 · 凋零3秒 · 退开或跳到背后"
func emerald_budget() -> int:
    var total:=0
    for spec in enemy_specs():
        if _has_emerald_reward(spec): total+=1
    for spec in fixed_pickup_specs():
        if spec.data.kind==PickupData.Kind.EMERALD: total+=spec.data.amount
    return total
func armory_positions() -> Array[float]: return [160.0,888.0,2288.0,3552.0]
func segments() -> Array[Dictionary]: return [{"x":0,"name":"前哨试刀"},{"x":960,"name":"越刃反击"},{"x":1600,"name":"骨阵夹击"},{"x":2336,"name":"金剑追击"},{"x":2976,"name":"重斧破阵"},{"x":3616,"name":"连弩封锁"},{"x":4384,"name":"剑弩夹击"}]
func level_title() -> String: return "堡垒试炼 · 骸骨与猪灵"
func result_hint() -> String: return "独立练习 · 初始40宝石 · 不影响远征"
func panel_detail() -> String: return "E 五武器换装 · 凋零随重试清除 · 第六关完整路线制作中"
func panel_title() -> String: return "试炼失败" if defeated else (finished_title if completed else "试炼暂停")
func check_environment() -> void: pass
func toast_anchor(width: float) -> Vector2:
    return Vector2(maxf(156,(640-width)/2),78) if is_instance_valid(wither) and wither.remaining>0 and width<=468 else Vector2((640-width)/2,78)
func weapon_hint_offset() -> Vector2: return Vector2(-202,11)
