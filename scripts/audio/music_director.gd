extends Node
## Two persistent voices: chapter/encounter changes crossfade without extra players.
const TRACKS := {
    "menu":"00_menu", "forest_ruins":"01_forest", "spiderwood":"02_spiderwood",
    "abandoned_mine":"03_mine", "tidal_ruins":"04_tide", "warped_border":"05_warped",
    "fortress_core":"06_fortress", "the_end":"07_end", "victory":"08_victory",
    "boss_captain":"boss_01_captain", "boss_queen":"boss_02_queen",
    "boss_ravager":"boss_03_ravager", "boss_guardian":"boss_04_guardian",
    "boss_rift":"boss_05_rift", "boss_wither":"boss_06_wither", "boss_dragon":"boss_07_dragon"
}
const TITLES := {"menu":"方块远征", "forest_ruins":"晨光中的第一跃", "spiderwood":"月下蛛影",
    "abandoned_mine":"裂岩节拍", "tidal_ruins":"深蓝回声", "warped_border":"紫焰之间",
    "fortress_core":"熔火与灵魂", "the_end":"最后的天空", "victory":"欢迎回家",
    "boss_captain":"白骨战鼓", "boss_queen":"毒雾王冠", "boss_ravager":"撼地狂奔",
    "boss_guardian":"深渊之眼", "boss_rift":"瞬影追猎", "boss_wither":"三首灾厄", "boss_dragon":"终焉之翼"}
const FADE_SECONDS := 0.85
const BASE_GAIN_DB := -8.0
var voices: Array[AudioStreamPlayer] = []
var weights: Array[float] = [0.0,0.0]
var active := -1
var current_id := ""
var transition_count := 0
var pause_gain := 1.0
var streams: Dictionary = {}

func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    for i in 2:
        var voice:=AudioStreamPlayer.new()
        voice.name="MusicVoice%d" % i
        voice.volume_db=-80.0
        add_child(voice)
        voices.append(voice)
    ControlSettings.audio_changed.connect(_apply_volume)

func track_stream(id: String) -> AudioStreamMP3:
    if not TRACKS.has(id): return null
    if streams.has(id): return streams[id]
    var stream:=load("res://assets/audio/music/%s.mp3" % TRACKS[id]) as AudioStreamMP3
    if stream==null: return null
    stream=stream.duplicate() as AudioStreamMP3
    stream.loop=true
    stream.loop_offset=0.0
    streams[id]=stream
    return stream

func prepare_track(id: String) -> void:
    # Load compressed music during level setup, not at the first boss attack.
    if not id.is_empty(): track_stream(id)

func play_track(id: String) -> void:
    if id==current_id or not TRACKS.has(id): return
    var stream:=track_stream(id)
    if stream==null: return
    var next:=0 if active<0 else 1-active
    # An interrupted fade always reuses the older voice, never creates a third one.
    voices[next].stop()
    weights[next]=0.0
    voices[next].stream=stream
    voices[next].volume_db=-80.0
    voices[next].play()
    active=next
    current_id=id
    transition_count+=1

func _process(delta: float) -> void:
    var scene:=get_tree().current_scene
    if is_instance_valid(scene) and scene.has_method("music_track_id"):
        play_track(scene.music_track_id())
    for i in voices.size():
        weights[i]=move_toward(weights[i],1.0 if i==active else 0.0,delta/FADE_SECONDS)
        if i!=active and weights[i]<=0.0 and voices[i].playing: voices[i].stop()
    # Settings and pause remain musical, at a gentler level. Victory stays full level.
    var target:=0.65 if get_tree().paused and current_id!="victory" else 1.0
    pause_gain=move_toward(pause_gain,target,delta*2.0)
    _apply_volume()

func _apply_volume() -> void:
    for i in voices.size():
        var gain:=weights[i]*ControlSettings.music_volume*pause_gain
        voices[i].volume_db=-80.0 if gain<=0.0001 else BASE_GAIN_DB+linear_to_db(gain)
