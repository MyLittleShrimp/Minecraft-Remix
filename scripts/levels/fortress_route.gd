extends "res://scripts/levels/wither_lab.gd"
const ROUTE_GROUPS := [[0],[1,2],[3],[4],[5],[6,7],[8,9,10],[11,12,13],[14,15,16]]
const ROUTE_HINTS := ["石柱挡火球 · 烈焰人下落时靠近攻击，也可返击火球","骸骨长廊：长剑锁向蓄力 · 跳背或退开反击","金剑蛮兵：追击较快 · 抢攻或诱招","金斧蛮兵：抬斧霸体 · 等重劈落空再进攻","连弩蛮兵：两次预警两支箭 · 装填时进攻","剑弩夹击：分开近战守卫，留意后排箭矢","灰烬交锋：地面先诱招 · 抓烈焰人低空窗口","骸骨防线：长剑与重斧 · 留意后排连弩","熔心突围：长剑与重斧封路 · 留意高空火球"]
var conduit_camera:=false
var last_safe:=Vector2(96,288)
func encounter_groups() -> Array: return ROUTE_GROUPS
func encounter_hint(room: int) -> String: return ROUTE_HINTS[room]
func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4S2"
    window_label="M4-S.2.1 Fortress Mixed Battles and Soul Conduit"
    hud_title="06 / 堡垒核心 · 前半路线"
    short_stage="M4-S.2.1"
    course_width=FortressCourse.WIDTH
    exit_x=13824
    finished_title="已抵达灵魂前哨"
    toast="突破外堡 → 解开灵魂封印 → 冲破熔心守军"
    toast_left=8
func enemy_specs() -> Array[Dictionary]:
    return [{"data":preload("res://resources/enemies/blaze.tres"),"x":1056,"y":132,"left":320,"right":1248},
        {"data":preload("res://resources/enemies/wither_skeleton.tres"),"x":2112,"left":1728,"right":2464},
        {"data":zombie_data,"x":2304,"left":1728,"right":2464},
        {"data":preload("res://resources/enemies/piglin_sword.tres"),"x":3104,"left":2784,"right":3296},
        {"data":preload("res://resources/enemies/piglin_axe.tres"),"x":3776,"left":3488,"right":4000},
        {"data":preload("res://resources/enemies/piglin_crossbow.tres"),"x":4592,"left":4256,"right":4896},
        {"data":preload("res://resources/enemies/piglin_sword.tres"),"x":5488,"left":5184,"right":5824},
        {"data":preload("res://resources/enemies/piglin_crossbow.tres"),"x":5696,"left":5184,"right":5824},
        {"data":preload("res://resources/enemies/wither_skeleton.tres"),"x":7840,"left":7424,"right":8384},
        {"data":preload("res://resources/enemies/piglin_sword.tres"),"x":8048,"left":7424,"right":8384},
        {"data":preload("res://resources/enemies/blaze.tres"),"x":8192,"y":132,"left":7424,"right":8384},
        {"data":preload("res://resources/enemies/wither_skeleton.tres"),"x":10432,"left":10112,"right":11072},
        {"data":preload("res://resources/enemies/piglin_axe.tres"),"x":10624,"left":10112,"right":11072},
        {"data":preload("res://resources/enemies/piglin_crossbow.tres"),"x":10832,"left":10112,"right":11072},
        {"data":preload("res://resources/enemies/wither_skeleton.tres"),"x":12064,"left":11648,"right":12800},
        {"data":preload("res://resources/enemies/piglin_axe.tres"),"x":12368,"left":11648,"right":12800},
        {"data":preload("res://resources/enemies/blaze.tres"),"x":12512,"y":132,"left":11648,"right":12800}]
func create_enemy(spec: Dictionary) -> RemixEnemy:
    if spec.data.kind==EnemyData.Kind.BLAZE:
        var blaze:=BlazeEnemy.new()
        blaze.arena_bounds=Vector2(spec.left,spec.right)
        blaze.cool_behind_cover=true
        return blaze
    return super.create_enemy(spec)
func enemy_id(index: int) -> StringName: return StringName("fortress_route_%d"%index)
func _set_enemy_active(enemy: RemixEnemy,value: bool) -> void:
    if enemy is BlazeEnemy:
        if value: enemy.activate()
        else:
            enemy.active=false
            enemy.pending_shot=false
            enemy.clear_balls()
            enemy.receiver.set_deferred("collision_layer",0)
    else: super._set_enemy_active(enemy,value)
func checkpoint_specs() -> Array[Dictionary]:
    return [{"id":&"fortress_start","label":"堡垒桥头","x":96.0,"heals":false},
        {"id":&"fortress_bones","label":"骸骨路标","x":1360.0,"heals":false},
        {"id":&"fortress_arsenal","label":"武库路标","x":2560.0,"heals":false},
        {"id":&"fortress_bolts","label":"连弩路标","x":4096.0,"heals":false},
        {"id":&"fortress_furnace_entry","label":"熔炉检修站","x":5952.0,"heals":false},
        {"id":&"fortress_ash","label":"外堡破口","x":7296.0,"heals":false},
        {"id":&"fortress_conduit_entry","label":"灵魂导流室","x":8544.0,"heals":false},
        {"id":&"fortress_bone_line","label":"防线前哨","x":9920.0,"heals":false},
        {"id":&"fortress_core","label":"熔心前哨","x":11328.0,"heals":false},
        {"id":&"fortress_outpost","label":"灵魂前哨","x":13024.0,"heals":false}]
func checkpoint_requirements(index: int) -> Array:
    return [[],[0],[0,1,2],[0,1,2,3,4],range(8),range(8),range(11),range(11),range(14),range(17)][index]
func armory_positions() -> Array[float]: return [160.0,1360.0,2560.0,4096.0,5952.0,7296.0,8544.0,9920.0,11328.0,13024.0]
func block_specs() -> Array[Dictionary]:
    return [{"id":&"fortress_apple_a","x":1400,"y":208,"data":apple_data},
        {"id":&"fortress_high_bread","x":1688,"y":144,"data":BREAD_DATA},
        {"id":&"fortress_bread_b","x":3392,"y":208,"data":BREAD_DATA},
        {"id":&"fortress_apple_b","x":4128,"y":208,"data":apple_data},
        {"id":&"fortress_apple_c","x":5992,"y":208,"data":apple_data},
        {"id":&"fortress_exit_bread","x":7208,"y":144,"data":BREAD_DATA},
        {"id":&"fortress_ash_apple","x":7336,"y":208,"data":apple_data},
        {"id":&"fortress_ash_bread","x":8456,"y":208,"data":BREAD_DATA},
        {"id":&"fortress_conduit_apple","x":8584,"y":208,"data":apple_data},
        {"id":&"fortress_conduit_bread","x":9480,"y":144,"data":BREAD_DATA},
        {"id":&"fortress_line_apple","x":9960,"y":208,"data":apple_data},
        {"id":&"fortress_line_bread","x":11240,"y":208,"data":BREAD_DATA},
        {"id":&"fortress_core_apple","x":11368,"y":208,"data":apple_data},
        {"id":&"fortress_last_apple","x":13064,"y":208,"data":apple_data},
        {"id":&"fortress_last_bread","x":13496,"y":144,"data":BREAD_DATA}]
func mechanism_ids() -> Array[String]: return ["fortress_furnace","fortress_conduit"]
func completion_mechanisms() -> Array[String]: return mechanism_ids()
func _physics_process(delta: float) -> void:
    if defeated or completed or course_paused: return
    if player.position.x>=exit_x and (not course.furnace.active or not course.conduit.active):
        toast="先完成熔炉和灵魂导流，再抵达前哨"
        toast_left=2
        return
    var focus: bool=player.position.x>8648 and player.position.x<9320
    if focus!=conduit_camera:
        conduit_camera=focus
        camera.set_region_smooth(8648 if focus else 0,9288 if focus else -1,0.6)
    if player.is_on_floor() and course.safe_floor(player.position): last_safe=player.position
    super._physics_process(delta)
func check_environment() -> void:
    if defeated or completed or course_paused or player.position.y<=432: return
    var fall:=DamageEvent.create(course,0,4)
    fall.bypass_invulnerability=true
    fall.protection_override=1.0
    health.queue_damage(fall)
    equipment.suspend_input()
    clear_projectiles()
    if player.position.x>=6000 and player.position.x<7056 and not course.furnace.active:
        course.furnace.apply_state(false)
        last_safe=Vector2(6032,288)
    player.reset_at(last_safe)
    camera.reset_to_target()
    toast="失足 -4 · 回到安全落点；未完成的 TNT 已送回补给座"
    toast_left=4
func _activate_checkpoint(index: int) -> void:
    if index>=5 and not course.furnace.active: return
    if index>=7 and not course.conduit.active: return
    super._activate_checkpoint(index)
func nearby_conduit() -> bool:
    return not defeated and not completed and not course_paused and not transitioning and not player.controls_locked and player.is_on_floor() and not input_panel.visible and not loadout_panel.visible and course.conduit.nearby_rotor(player.position)>=0
func nearby_furnace() -> bool:
    return not defeated and not completed and not course_paused and not transitioning and not player.controls_locked and player.is_on_floor() and not input_panel.visible and not loadout_panel.visible and course.furnace.can_interact()
func _unhandled_input(event: InputEvent) -> void:
    if nearby_furnace() or nearby_conduit():
        var keyboard: bool=event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_E and not ControlSettings.gamepad_active()
        var pad: bool=(event is InputEventJoypadButton or event is InputEventJoypadMotion) and ControlSettings.event_pressed(event,"aim_up")
        if keyboard or pad:
            if nearby_conduit(): course.conduit.interact(player.position)
            else: course.furnace.interact()
            get_viewport().set_input_as_handled()
            return
    super._unhandled_input(event)
func restart_course() -> void:
    course.restore_mechanisms({})
    super.restart_course()
    last_safe=player.position
    conduit_camera=false
    camera.set_region(0)
func restore_checkpoint() -> void:
    if not defeated: return
    super.restore_checkpoint()
    last_safe=player.position
    conduit_camera=false
    camera.set_region(0)
func can_reset_transport() -> bool:
    return checkpoint_index in [4,6] and not defeated and not completed and not transitioning
func reset_transport() -> void:
    if not can_reset_transport(): return
    var hp: int=health.current
    var food: float=hunger.value
    defeated=true
    restore_checkpoint()
    health.current=mini(hp,snapshot.player_health)
    health.health_changed.emit(health.current,health.max_health)
    hunger.restore(minf(food,snapshot.player_food))
    toast="机关房已重置 · 已存战果保留，生命与饱食不增加"
    toast_left=5
func segments() -> Array[Dictionary]:
    return [{"x":0,"name":"烈焰桥头"},{"x":1360,"name":"骸骨长廊"},{"x":2784,"name":"金剑武库"},{"x":3488,"name":"金斧守卫"},{"x":4096,"name":"连弩封锁"},{"x":5184,"name":"武库夹击"},{"x":5888,"name":"熔炉检修"},{"x":7056,"name":"外堡破口"},{"x":7424,"name":"灰烬交锋"},{"x":8448,"name":"灵魂导流"},{"x":9352,"name":"断桥追击"},{"x":10112,"name":"骸骨防线"},{"x":11648,"name":"熔心突围"},{"x":13024,"name":"灵魂前哨"}]
func level_title() -> String: return "06 / 堡垒核心 · 前半路线"
func panel_title() -> String: return "堡垒突围失败" if defeated else (finished_title if completed else "堡垒暂停")
func panel_detail() -> String:
    if can_reset_transport(): return "本房回滚"
    return "独立路线试玩 · 凋灵 Boss 与正式跨关接续后续开放"
