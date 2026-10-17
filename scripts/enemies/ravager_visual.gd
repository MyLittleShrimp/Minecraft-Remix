extends Node2D
## Presentation follows battle state/timers; never alters physics or combat timing.
var clock:=0.0
var state_seconds:=0.0
var death_time:=0.0
var last_battle: int=-1
var previous_timer:=0.0
var recovery_pose:=0
var long_stun:=false
var animation_frame:=0
var phase_index:=0

func _physics_process(delta: float) -> void:
    var boss:=get_parent() as RavagerEnemy
    clock+=delta
    state_seconds+=delta
    var renewed_recovery:=boss.battle==RavagerEnemy.Battle.RECOVER and boss.timer>previous_timer+0.1
    if last_battle!=boss.battle or renewed_recovery:
        state_seconds=0
        if boss.battle==RavagerEnemy.Battle.RECOVER:
            long_stun=boss.timer>=1.8
            recovery_pose=17 if last_battle==RavagerEnemy.Battle.STOMP else (14 if last_battle==RavagerEnemy.Battle.HORN else 0)
        last_battle=boss.battle
    previous_timer=boss.timer
    phase_index=int(boss.second_phase)
    if boss.state==RemixEnemy.State.DEAD:
        death_time+=delta
        animation_frame=21+mini(2,int(death_time/0.22))
    else:
        death_time=0
        select_frame(boss)
    queue_redraw()

func warning_frame(boss: RavagerEnemy,seconds: float,start: int,count: int) -> int:
    var progress:=1.0-clampf(boss.timer/maxf(seconds,0.01),0,1)
    return start+mini(count-1,int(progress*count))

func select_frame(boss: RavagerEnemy) -> void:
    match boss.battle:
        RavagerEnemy.Battle.APPROACH:
            animation_frame=3+posmod(int(clock*8),3) if absf(boss.velocity.x)>1 else int(clock*2)%3
        RavagerEnemy.Battle.TURN:
            animation_frame=3+mini(2,int(state_seconds/0.15))
        RavagerEnemy.Battle.CHARGE_WARNING:
            animation_frame=warning_frame(boss,boss.phase_value(boss.tuning().charge_warning),6,3)
        RavagerEnemy.Battle.CHARGE:
            animation_frame=9+posmod(int(state_seconds*13),3)
        RavagerEnemy.Battle.HORN_WARNING:
            animation_frame=warning_frame(boss,boss.phase_value(boss.tuning().horn_warning),12,2)
        RavagerEnemy.Battle.HORN:
            animation_frame=14
        RavagerEnemy.Battle.STOMP_WARNING:
            animation_frame=warning_frame(boss,boss.phase_value(boss.tuning().stomp_warning),15,2)
        RavagerEnemy.Battle.STOMP:
            animation_frame=17 if boss.pending_wave or boss.timer>0.37 else 16
        RavagerEnemy.Battle.RECOVER:
            if long_stun:
                animation_frame=20 if boss.timer<0.3 else 18+int(state_seconds*5)%2
            elif state_seconds<0.18:
                animation_frame=recovery_pose
            else:
                animation_frame=int(clock*2)%3
        RavagerEnemy.Battle.PHASE_CHANGE:
            animation_frame=18+mini(2,int(state_seconds/0.27))
        _:
            animation_frame=int(clock*2)%3

func _draw() -> void:
    var boss:=get_parent() as RavagerEnemy
    var dead:=boss.state==RemixEnemy.State.DEAD
    var tint:=Color.WHITE
    if dead: tint=Color(0.8,0.8,0.85,lerpf(1,0.48,clampf((death_time-0.7)/0.5,0,1)))
    elif boss.flash_left>0.08: tint=Color(1.45,1.35,1.2)
    elif boss.battle==RavagerEnemy.Battle.PHASE_CHANGE: tint=Color(1.0+0.25*sin(state_seconds*20),1,1)
    draw_rect(Rect2(-42,-2,84,3),Color(0.03,0.06,0.08,0.32))
    RavagerArt.actor(self,phase_index,animation_frame,boss.facing,tint)
    if dead: return
    draw_set_transform(Vector2.ZERO,0,Vector2(boss.facing,1))
    if boss.battle==RavagerEnemy.Battle.CHARGE:
        for i in 4:
            var age:=fmod(clock*8+i*0.25,1)
            draw_rect(Rect2(-44-age*22,-3-age*9,3,3),Color(0.7,0.6,0.43,(1-age)*0.6))
    if boss.exposed():
        for i in 3:
            var angle:=clock*5+i*TAU/3
            var p:=Vector2(cos(angle)*16,-64+sin(angle)*3)
            draw_rect(Rect2(p,Vector2(3,3)),Color("f9de92"))
    if boss.battle==RavagerEnemy.Battle.TURN:
        draw_line(Vector2(-17,-77),Vector2(24,-77),Color("ffe3a1"),3)
        draw_line(Vector2(17,-84),Vector2(25,-77),Color("ffe3a1"),3)
        draw_line(Vector2(25,-77),Vector2(17,-70),Color("ffe3a1"),3)
    if boss.battle in [RavagerEnemy.Battle.CHARGE_WARNING,RavagerEnemy.Battle.HORN_WARNING,RavagerEnemy.Battle.STOMP_WARNING]:
        var width: float=76 if boss.battle==RavagerEnemy.Battle.HORN_WARNING else (boss.tuning().charge_distance+40 if boss.battle==RavagerEnemy.Battle.CHARGE_WARNING else 70)
        draw_rect(Rect2(0,-3,width,3),Color("efb65f"))
        for x in range(14,int(width),28):
            draw_line(Vector2(x,-9),Vector2(x+7,-5),Color("ffda87"),2)
            draw_line(Vector2(x+7,-5),Vector2(x,-1),Color("ffda87"),2)
    draw_set_transform(Vector2.ZERO)
    if boss.battle==RavagerEnemy.Battle.STOMP_WARNING or (boss.battle==RavagerEnemy.Battle.STOMP and boss.waves_left>0):
        var radius:=46.0+(1.0-clampf(boss.timer/0.8,0,1))*30.0
        draw_line(Vector2(-radius,-2),Vector2(radius,-2),Color("ffd388"),3)
        for direction in [-1,1]: draw_rect(Rect2(direction*radius-2,-10,4,7),Color("ffe6b0"))
    if boss.flash_left>0:
        draw_string(boss.ui_font,Vector2(-9,-72-(0.18-boss.flash_left)*30),"-%d" % boss.last_damage,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffe4a1"))
