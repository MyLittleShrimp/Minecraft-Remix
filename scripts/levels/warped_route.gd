extends "res://scripts/levels/campaign_level.gd"
@export var campaign_mode:=false
const BLAZE=preload("res://resources/enemies/blaze.tres")
const ELITE=preload("res://resources/enemies/enderman_elite.tres")
const ENDER=preload("res://resources/enemies/enderman.tres")
const PARKOUR_ARCHER=preload("res://resources/enemies/warped_archer.tres")
const GHAST=preload("res://resources/enemies/ghast.tres")
const ROOM_TARGETS: Array[Array]=[[0],[4],[6],[9,10],[15,16,17],[14]]
var arena_active:=false
var elite: EndermanElite
var blaze: BlazeEnemy
var story_pearls:=0
var intro_left:=0.0
var active_room: int=-1
var optional_guard: EndermanEnemy
var ghast: GhastEnemy
var duet: Array[GhastEnemy]=[]
var duet_volley: GhastVolley
var parkour_active:=false
var parkour_return:=Vector2(6848,288)
var parkour_falls:=0
func _ready() -> void:
    if not campaign_mode:
        saves.enabled=false
        saves.pending_resume.clear()
    duet_volley=GhastVolley.new()
    $World.add_child(duet_volley)
    super._ready()
    player.z_index=2
    practice_target.position.x=240
    practice_target.label="试武木靶"
    _reset_rooms()
    ghast.cue.connect(func(id: StringName) -> void: sound.play_effect(id))
    for actor in duet:
        actor.cue.connect(func(id: StringName) -> void: sound.play_effect(id))
func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4O"
    stage_version=ProjectSettings.get_setting("application/config/version")
    window_label="M4-Q.2 Bridge Assault"
    hud_title="诡异边界 · 路线试玩"
    short_stage="M4-Q.2"
    course_width=WarpedCourse.WIDTH
    exit_x=10288
    finished_title="取得末影珍珠"
    toast="路线试玩 · 路标仅本次有效 · 20练习宝石"
    toast_left=5
    if campaign_mode:
        stage_id="M4P"
        window_label="M4-Q.2 Bridge Assault"
        short_stage="M4-Q.2"
        hud_title="诡异边界 · 下界远征"
        finished_title="诡异边界，通关！"
        toast="第五章 · 诡异边界 · 寻找通往堡垒的线索"
func _enter_campaign_level() -> void:
    if campaign_mode:
        super._enter_campaign_level()
        return
    wallet.reset_to_entry(20)
    hunger.restore(20,true)
    campaign_settled=true
    equipment.configure_loadout(["netherite_sword","bow"])
    equipment.slot=0
func persist_checkpoint() -> void:
    if campaign_mode: super.persist_checkpoint()
func enemy_specs() -> Array[Dictionary]:
    var specs: Array[Dictionary]=[{"data":ENDER,"x":900,"room":0},{"data":zombie_data,"x":1450},
        {"data":skeleton_data,"x":1680},{"data":SPIDER_DATA,"x":2320},
        {"data":ENDER,"x":2940,"room":1},{"data":creeper_data,"x":3850},
        {"data":GHAST,"x":4500,"y":GhastEnemy.HIGH_Y,"room":2},
        {"data":zombie_data,"x":5330},{"data":SPIDER_DATA,"x":5510},
        {"data":GHAST,"x":6096,"y":GhastEnemy.HIGH_Y,"room":3,"side":0},
        {"data":GHAST,"x":6448,"y":GhastEnemy.HIGH_Y,"room":3,"side":1},
        {"data":PARKOUR_ARCHER,"x":7288,"y":256,"parkour":true},
        {"data":SPIDER_DATA,"x":7808,"y":240,"parkour":true},
        {"data":PARKOUR_ARCHER,"x":7872,"y":240,"parkour":true},
        {"data":ELITE,"x":9840,"room":5},
        {"data":BLAZE,"x":8656,"y":BlazeEnemy.HIGH_Y,"room":4},
        {"data":zombie_data,"x":8504,"room":4,"bridge_guard":true},
        {"data":SPIDER_DATA,"x":8776,"room":4,"bridge_guard":true}]
    for i in specs.size():
        specs[i].id=enemy_id(i)
        specs[i].no_loot=specs[i].data in [GHAST,ELITE,BLAZE] or specs[i].get("bridge_guard",false)
    return specs
func create_enemy(spec: Dictionary) -> RemixEnemy:
    if spec.get("bridge_guard",false):
        var guard: RemixEnemy=SpiderEnemy.new() if spec.data==SPIDER_DATA else RemixEnemy.new()
        guard.set_meta("bridge_guard",true)
        return guard
    if spec.get("parkour",false):
        var actor: RemixEnemy=SpiderEnemy.new() if spec.data==SPIDER_DATA else RemixEnemy.new()
        actor.set_meta("parkour",true)
        return actor
    if spec.data==BLAZE:
        blaze=BlazeEnemy.new()
        blaze.arena_bounds=WarpedCourse.ROOMS[4]
        return blaze
    if spec.data==ELITE:
        elite=EndermanElite.new()
        elite.guard_mode=true
        elite.encounter_bounds=WarpedCourse.ROOMS[5]+Vector2(18,-18)
        return elite
    if spec.data==ENDER:
        var enemy:=EndermanEnemy.new()
        enemy.guard_mode=true
        enemy.encounter_bounds=WarpedCourse.ROOMS[spec.room]+Vector2(18,-18)
        return enemy
    if spec.data==GHAST:
        if spec.room==3:
            var actor:=GhastEnemy.new()
            actor.arena_bounds=WarpedCourse.ROOMS[3]
            actor.cruise_bounds=Vector2(6032,6192) if spec.side==0 else Vector2(6352,6512)
            actor.volley=duet_volley
            duet.append(actor)
            return actor
        ghast=GhastEnemy.new()
        ghast.arena_bounds=WarpedCourse.ROOMS[2]
        return ghast
    return RemixEnemy.new()
func enemy_id(index: int) -> StringName: return StringName("warped_route_%d"%index)
func checkpoint_specs() -> Array[Dictionary]:
    return [{"id":&"warped_start","label":"边界武库","x":96.0,"heals":true},
        {"id":&"warped_forest","label":"菌林路标","x":1280.0,"heals":false},
        {"id":&"warped_bridge","label":"断桥前哨","x":3256.0,"heals":false},
        {"id":&"warped_ash","label":"灰烬路标","x":4816.0,"heals":false},
        {"id":&"warped_duet","label":"双影前哨","x":5728.0,"heals":false},
        {"id":&"warped_ramparts","label":"断垣前哨","x":6848.0,"heals":false},
        {"id":&"warped_warden","label":"裂隙前哨","x":9088.0,"heals":false}]
func checkpoint_requirements(index: int) -> Array:
    return range(14)+[15,16,17] if index==6 else range([0,1,5,7,9,11][index])
func _activate_checkpoint(index: int) -> void:
    if index==3 and not course.bridge_ready():
        toast="先点亮双靶、接通断桥，再记录前哨"
        toast_left=3
        return
    super._activate_checkpoint(index)
func block_specs() -> Array[Dictionary]:
    return [{"id":&"warped_apple_a","x":1312,"data":apple_data},
        {"id":&"warped_bread_a","x":1840,"y":144,"data":BREAD_DATA},
        {"id":&"warped_apple_b","x":3224,"data":apple_data},
        {"id":&"warped_bread_b","x":3952,"data":BREAD_DATA},
        {"id":&"warped_apple_c","x":4880,"data":apple_data},
        {"id":&"warped_apple_d","x":5784,"data":apple_data},
        {"id":&"warped_bread_c","x":5856,"data":BREAD_DATA},
        {"id":&"warped_apple_e","x":6912,"data":apple_data},
        {"id":&"warped_bread_d","x":7528,"y":128,"data":BREAD_DATA},
        {"id":&"warped_apple_f","x":9152,"data":apple_data},
        {"id":&"warped_bread_e","x":9280,"y":144,"data":BREAD_DATA}] + AdventureRewards.blocks("warped_border")
func fragile_specs() -> Array[Dictionary]: return [] + AdventureRewards.chests("warped_border")
func setup_content() -> void:
    optional_guard=load("res://scripts/enemies/branch_enderman.gd").new()
    optional_guard.data=ENDER
    optional_guard.target=player
    optional_guard.view_camera=camera
    optional_guard.ui_font=ui_font
    optional_guard.position=Vector2(2184,160)
    optional_guard.encounter_bounds=Vector2(1960,2280)
    $World.add_child(optional_guard)
    optional_guard.defeated.connect(_optional_loot)
    optional_guard.health.damaged.connect(func(_e: DamageEvent) -> void: sound.play_effect(&"hit"))
    super.setup_content()
func _place_fixed_pickups() -> void:
    for spec in fixed_pickup_specs(): _spawn_identified(spec.data,spec.at,1,run_id,spec.id)
func _optional_loot(_enemy: RemixEnemy) -> void:
    # Unique IDs are snapshotted with pending/live pickups; retries cannot duplicate them.
    for i in 3: _queue_drop(emerald_data,Vector2(2110+i*28,135),1,StringName("warped_optional_%d"%i))
    _queue_drop(BREAD_DATA,Vector2(2232,135),-1,&"warped_optional_bread")
    toast="支路挑战完成 · 上层留下 3 绿宝石和面包"
    toast_left=4
func _enemy_loot(enemy: RemixEnemy) -> void:
    if enemy.get_meta("bridge_guard",false): return
    if enemy.get_meta("parkour",false) and enemy.data.kind==EnemyData.Kind.SKELETON:
        # A knock-off kill leaves its one reward on the reachable home island.
        _queue_drop(emerald_data,enemy.spawn_point+Vector2(0,-22),1,StringName("enemy/"+str(enemy.get_meta("object_id"))))
    elif not enemy is GhastEnemy and not enemy is EndermanElite and not enemy is BlazeEnemy: super._enemy_loot(enemy)
func _make_snapshot(index: int) -> CheckpointSnapshot:
    var saved:=super._make_snapshot(index)
    if campaign_mode: saved.optional_health["optional_enderman"]=optional_guard.health.current
    else: saved.wildlife_health["optional_enderman"]=optional_guard.health.current
    return saved
func _reset_rooms() -> void:
    active_room=-1
    arena_active=false
    story_pearls=int(snapshot.story_items.get("ender_pearl",0)) if campaign_mode and completed else 0
    course.relic_gate.set_closed(story_pearls<3)
    parkour_active=false
    parkour_return=Vector2(6848,288)
    for i in range(11,14):
        targets[i].set_physics_process(false)
        targets[i].receiver.set_deferred("collision_layer",0)
    duet_volley.reset()
    camera.set_region(0)
    for i in ROOM_TARGETS.size():
        course.entries[i].set_closed(false)
        course.exits[i].set_closed(not room_cleared(i))
        for index in ROOM_TARGETS[i]:
            var enemy: RemixEnemy=targets[index]
            enemy.receiver.set_deferred("collision_layer",0)
            if enemy is GhastEnemy:
                enemy.active=false
                enemy.flight=GhastEnemy.Flight.DEAD if enemy.health.current<=0 else GhastEnemy.Flight.DORMANT
            elif enemy is BlazeEnemy:
                enemy.active=false
                enemy.flight=BlazeEnemy.Flight.DEAD if enemy.health.current<=0 else BlazeEnemy.Flight.DORMANT
            elif enemy.get_meta("bridge_guard",false):
                enemy.set_physics_process(false)
            else:
                enemy.encounter_enabled=false
                enemy.provoked=false
func room_cleared(index: int) -> bool:
    return ROOM_TARGETS[index].all(func(id: int) -> bool: return targets[id].health.current<=0)
func restart_course() -> void:
    parkour_falls=0
    optional_guard.reset_target()
    course.restore_mechanisms({})
    super.restart_course()
    _reset_rooms()
func restore_checkpoint() -> void:
    if not defeated: return
    super.restore_checkpoint()
    optional_guard.reset_target()
    optional_guard.health.current=(snapshot.optional_health if campaign_mode else snapshot.wildlife_health).get("optional_enderman",ENDER.max_health)
    if optional_guard.health.current<=0:
        optional_guard.state=RemixEnemy.State.DEAD
        optional_guard.receiver.set_deferred("collision_layer",0)
    _reset_rooms()
func _physics_process(delta: float) -> void:
    if course_paused or defeated or completed: return
    if not parkour_active and player.position.x>=7008 and player.is_on_floor():
        parkour_active=true
        for i in range(11,14):
            if targets[i].health.current<=0: continue
            targets[i].set_physics_process(true)
            targets[i].receiver.collision_layer=16
    # A neutral branch cannot be aggroed by projectiles on the ground route.
    optional_guard.encounter_enabled=optional_guard.inside_encounter(player.position) and optional_guard.health.current>0
    optional_guard.receiver.collision_layer=16 if optional_guard.encounter_enabled else 0
    if active_room>=0:
        if room_cleared(active_room):
            course.entries[active_room].set_closed(false)
            course.exits[active_room].set_closed(false)
            camera.set_region_smooth(0,-1,0.7)
            active_room=-1
            arena_active=false
            if elite.health.current<=0:
                toast="守门者已击败 · 前方祭台领取 3 颗末影珍珠"
                toast_left=4
    else:
        for i in ROOM_TARGETS.size():
            var bounds:=WarpedCourse.ROOMS[i]
            if room_cleared(i): continue
            if player.position.x>=bounds.x+32 and player.position.x<bounds.y and player.is_on_floor():
                active_room=i
                arena_active=i==5
                course.entries[i].set_closed(true)
                camera.set_region_smooth(bounds.x,bounds.y,0.9)
                for index in ROOM_TARGETS[i]:
                    var enemy: RemixEnemy=targets[index]
                    if enemy.health.current<=0: continue
                    if enemy is GhastEnemy or enemy is BlazeEnemy:
                        enemy.activate()
                        if i==3 and index==10: enemy.timer=2.15
                        toast_left=0
                    elif enemy.get_meta("bridge_guard",false):
                        enemy.set_physics_process(true)
                        enemy.receiver.set_deferred("collision_layer",16)
                        enemy.hitstun=0.8
                    else: enemy.activate_guard()
            break
    if player.position.x>=exit_x and story_pearls<3:
        play_seconds+=delta
        toast="前方祭台尚未领取末影珍珠"
        toast_left=2
        return
    super._physics_process(delta)
func _unhandled_input(event: InputEvent) -> void:
    if not course_paused and not defeated and not completed and not player.controls_locked and not input_panel.visible and not loadout_panel.visible:
        var keyboard: bool=event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_E and not ControlSettings.gamepad_active()
        var pad: bool=(event is InputEventJoypadButton or event is InputEventJoypadMotion) and ControlSettings.event_pressed(event,"aim_up")
        if keyboard or pad:
            if claim_pearls():
                get_viewport().set_input_as_handled()
                return
            for i in WarpedCourse.LEVERS.size():
                if player.is_on_floor() and player.position.distance_to(WarpedCourse.LEVERS[i])<27:
                    course.operate_lever(i)
                    get_viewport().set_input_as_handled()
                    return
    super._unhandled_input(event)
func check_environment() -> void:
    if defeated or completed or course_paused: return
    if player.position.x>=6848 and player.is_on_floor():
        var treads: Array[Rect2]=[Rect2(6848,288,256,224)]
        treads.append_array(WarpedCourse.PARKOUR_STONES)
        treads.append(Rect2(8224,288,2144,224))
        for tread in treads:
            if absf(player.position.y-tread.position.y)<2 and player.position.x>=tread.position.x+20 and player.position.x<=tread.end.x-20:
                parkour_return=Vector2(player.position.x,tread.position.y)
    if player.position.y<388: return
    if player.position.x>=7000:
        var fall:=DamageEvent.create(course,0,4)
        fall.bypass_invulnerability=true
        fall.protection_override=1.0
        health.queue_damage(fall)
        equipment.suspend_input()
        player.reset_at(parkour_return)
        camera.reset_to_target()
        parkour_falls+=1
        toast="失足 -4生命 · 返回上次站稳处"
        toast_left=3
        return
    var bank:=3368.0 if player.position.x<3536 else 3704.0
    if player.position.x<3700 and not course.bridge_ready(): bank=3368.0
    if player.position.x>4700: bank=4952.0 if player.position.x<5036 else 5120.0
    var event:=DamageEvent.create(course,0,4)
    health.queue_damage(event)
    equipment.suspend_input()
    player.reset_at(Vector2(bank,288))
    camera.reset_to_target()
    toast="坠落 -4生命 · 回到近岸；机关进度保留"
    toast_left=3
func emerald_budget() -> int: return 26 # Eight enemies + four fixed + three optional + eleven exploration gems.
func armory_positions() -> Array[float]: return [160.0,1280.0,3256.0,4816.0,5728.0,6848.0,9088.0]
func segments() -> Array[Dictionary]:
    return [{"x":0,"name":"边界武库"},{"x":512,"name":"菌林封印"},{"x":1200,"name":"诡异菌林"},
        {"x":1960,"name":"中立奖励支路"},{"x":2560,"name":"双层菌台"},{"x":3200,"name":"双靶放桥"},
        {"x":4096,"name":"灰烬空域"},{"x":4800,"name":"断桥冲刺"},{"x":5500,"name":"双影前哨"},
        {"x":5952,"name":"灰烬双影"},{"x":6592,"name":"断垣前哨"},{"x":7008,"name":"断垣突围"},{"x":8224,"name":"烈焰桥头"},{"x":8896,"name":"裂隙前哨"},{"x":9408,"name":"裂隙守门者"},{"x":10048,"name":"封存的珍珠"}]
func level_title() -> String: return "诡异边界" if campaign_mode else "诡异边界试玩"
func panel_title() -> String:
    if campaign_mode: return "诡异边界 · 再试一次" if defeated else (finished_title if completed else "诡异边界 · 暂停")
    return "路线试玩失败" if defeated else (finished_title if completed else "路线试玩暂停")
func panel_detail() -> String:
    if defeated: return super.panel_detail()
    if campaign_mode:
        if completed:
            return "珍珠 3/3 · 保存未成功，请重试保存" if saves.last_error!=OK else "末影珍珠 3/3 已保存 · 可前往第六关堡垒核心"
        return "路标自动保存 · 未结算收集与战斗进度随重试回滚"
    return "本次路标可重试 · 独立试玩，不写远征档" if not completed else "试玩完成 · 正式远征可继续第六关堡垒核心"

func next_level_path() -> String:
    return CampaignCatalog.scene_path("fortress_core") if campaign_mode else ""

func toast_anchor(width: float) -> Vector2:
    # Leave the centre clear when jumping from the tall ramparts.
    if player.position.x>=7008 and player.position.x<=8224:
        return Vector2(12,78) if width<280 else Vector2((640-width)/2,254)
    return Vector2((640-width)/2,78)

func boss_actor() -> RemixEnemy: return elite
func boss_name() -> String: return "裂隙守门者"
func claim_pearls() -> bool:
    if elite.health.current>0 or story_pearls>0 or not player.is_on_floor(): return false
    if player.position.distance_to(Vector2(10160,288))>32: return false
    story_pearls=3
    course.relic_gate.set_closed(false)
    toast="末影珍珠 +3 · 带着线索前往堡垒核心"
    toast_left=4
    sound.play_stream(PICKUP_SOUND)
    return true

func fixed_pickup_specs() -> Array[Dictionary]:
    var result: Array[Dictionary]=[]
    for i in 4: result.append({"id":"warped_fixed_%d"%i,"data":emerald_data,"at":Vector2([1760,1904,3780,5216][i],260)})
    result.append_array(ExplorationRewards.specs("warped_border"))
    return result
func optional_enemy_specs() -> Array[Dictionary]:
    return [{"id":"optional_enderman","data":ENDER}]
func extra_drop_specs() -> Array[Dictionary]:
    var result: Array[Dictionary]=[{"id":"warped_optional_bread","data":BREAD_DATA}]
    for i in 3: result.append({"id":"warped_optional_%d"%i,"data":emerald_data})
    return result
func mechanism_ids() -> Array[String]: return ["warped_bridge_0","warped_bridge_1"]
func mechanism_requirements(index: int) -> Array[String]: return mechanism_ids() if index>=3 else []
func completion_mechanisms() -> Array[String]: return mechanism_ids()

func wildlife_specs() -> Array[Dictionary]: return WildlifeContent.specs("warped_border")
