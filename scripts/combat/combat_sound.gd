class_name CombatSound
extends Node
## Original synthesized placeholders. Local to the level, no global bus changes.
const STREAMS := {
    &"ghast_warn": preload("res://assets/audio/ghast_warn.wav"),
    &"ghast_fire": preload("res://assets/audio/ghast_fire.wav"),
    &"ghast_reflect": preload("res://assets/audio/ghast_reflect.wav"),
    &"sword": preload("res://assets/audio/sword.wav"),
    &"arrow": preload("res://assets/audio/arrow.wav"),
    &"hit": preload("res://assets/audio/hit.wav"),
    &"fuse": preload("res://assets/audio/fuse.wav"),
    &"explosion": preload("res://assets/audio/explosion.wav")
}
var muted: bool = false

func play_effect(id: StringName) -> void:
    if STREAMS.has(id):
        play_stream(STREAMS[id])

func play_stream(stream: AudioStream) -> void:
    if muted or DisplayServer.get_name() == "headless" or get_child_count() >= 10:
        return
    var voice := AudioStreamPlayer.new()
    voice.stream = stream
    voice.volume_db = -16.0
    add_child(voice)
    voice.finished.connect(voice.queue_free)
    voice.play()

func clear_active() -> void:
    for voice in get_children():
        voice.stop()
        voice.queue_free()
