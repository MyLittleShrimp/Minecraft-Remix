extends "res://scripts/levels/ravager_lab.gd"
## Weapon preview stays outside the campaign unlock list and save format.
var trial_guards: Array[RemixEnemy]=[]
var guards_requested:=false
func _ready() -> void:
    super._ready()
    practice_target=TrainingDummy.new()
    practice_target.hit_points=80
    practice_target.label="试刺木靶"
    practice_target.ui_font=ui_font
    practice_target.position=Vector2(224,288)
    $World.add_child(practice_target)
    practice_target.health.died.connect(func() -> void:
        var epoch: int=run_id
        await get_tree().create_timer(3.0,false).timeout
        if is_instance_valid(practice_target) and run_id==epoch: practice_target.reset_target())

func configure_stage() -> void:
    super.configure_stage()
    stage_id="M4H2"
    window_label="M4-H.2 Sky Lightning Trial"
    hud_title="三叉戟试炼"
    short_stage="M4-H.2"
    finished_title="三叉戟试炼，完成！"
    toast="L天降雷霆 · 自动锁定最多3敌 · 落点范围伤害"
    toast_left=10

func _enter_campaign_level() -> void:
    wallet.reset_to_entry(40)
    hunger.restore(20,true)
    campaign_settled=true
    equipment.configure_loadout(["trident","bow"])
    equipment.slot=0

func armory_positions() -> Array[float]: return []
func level_title() -> String: return "三叉戟试炼"
func segments() -> Array[Dictionary]: return [{"x":0,"name":"试刺与投掷"},{"x":416,"name":"雷霆斗场"},{"x":1300,"name":"试炼出口"}]
func result_hint() -> String: return "独立练习 · 初始40宝石 · 不影响远征"
func panel_detail() -> String: return "R恢复练习宝石 · K切弓 · 暂停可返回主菜单"
func status_hint() -> String: return ""

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if course_paused or defeated or completed: return
    if arena_active and ravager.active and not guards_requested:
        guards_requested=true
        _spawn_trial_guards.call_deferred(run_id)

func _spawn_trial_guards(epoch: int) -> void:
    if run_id!=epoch or not arena_active or defeated or completed or ravager.health.current<=0: return
    for x in [616.0,760.0]:
        var guard:=SpiderEnemy.new()
        guard.data=SPIDER_DATA.duplicate()
        guard.data.label="雷霆试炼护卫"
        guard.data.awareness=480
        guard.data.patrol_radius=100
        guard.position=Vector2(x,288)
        guard.target=player
        guard.view_camera=camera
        guard.ui_font=ui_font
        $World.add_child(guard)
        guard.hitstun=0.35
        guard.health.damaged.connect(func(_event: DamageEvent) -> void: sound.play_effect(&"hit"))
        trial_guards.append(guard)

func _clear_trial_guards() -> void:
    for guard in trial_guards:
        if is_instance_valid(guard):
            guard.process_mode=Node.PROCESS_MODE_DISABLED
            guard.receiver.set_deferred("collision_layer",0)
            guard.queue_free()
    trial_guards.clear()

func _enemy_loot(enemy: RemixEnemy) -> void:
    _clear_trial_guards()
    super._enemy_loot(enemy)

func _reset_arena() -> void:
    _clear_trial_guards()
    guards_requested=false
    super._reset_arena()
