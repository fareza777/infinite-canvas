class_name AdsService
extends Node

signal state_changed
signal reward_earned
signal notice(text: String, icon: String, color: Color)

const BANNER_HEIGHT := 112.0

var bridge = null
var available := false
var enabled := false
var overlay_hidden := true
var banner_visible := false
var rewarded_pending := false
var last_error := ""
var _poll: Timer
var _reward_timer: Timer
var _reward_ticks := 0
var _last_banner := false


func _ready() -> void:
	if not OS.has_feature("android"):
		last_error = "Ads are available in the Android build."
		return
	bridge = JavaClassWrapper.wrap("com.godot.game.AdBridge")
	if bridge == null or not bridge.has_java_method("init"):
		bridge = null
		last_error = "AdMob bridge is unavailable in this build."
		return
	available = true
	_poll = Timer.new()
	_poll.wait_time = 1.0
	_poll.timeout.connect(_tick)
	add_child(_poll)
	_poll.start()
	_reward_timer = Timer.new()
	_reward_timer.wait_time = 0.5
	_reward_timer.timeout.connect(_poll_reward)
	add_child(_reward_timer)
	call_deferred("_initialize_bridge")


func _initialize_bridge() -> void:
	if bridge == null:
		return
	bridge.init()
	if JavaClassWrapper.get_exception() != null:
		last_error = str(JavaClassWrapper.get_exception())
		available = false
		notice.emit("AdMob could not initialize", "warning", Kit.DANGER)
		return
	bridge.setOverlayHidden(true)
	state_changed.emit()


func set_enabled(on: bool) -> void:
	enabled = on and available
	if bridge == null:
		banner_visible = false
		state_changed.emit()
		return
	bridge.setAdsEnabled(enabled)
	bridge.setOverlayHidden(overlay_hidden or not enabled)
	if not enabled:
		banner_visible = false
	_emit_if_changed()


func set_overlay_hidden(hidden: bool) -> void:
	overlay_hidden = hidden
	if bridge != null:
		bridge.setOverlayHidden(hidden or not enabled)
	_emit_if_changed()


func _tick() -> void:
	if bridge == null:
		return
	banner_visible = enabled and not overlay_hidden and bridge.isBannerVisible()
	if banner_visible != _last_banner:
		_last_banner = banner_visible
		state_changed.emit()


func _emit_if_changed() -> void:
	var before := _last_banner
	banner_visible = enabled and not overlay_hidden and bridge != null and bridge.isBannerVisible()
	if banner_visible != before:
		_last_banner = banner_visible
	state_changed.emit()


func is_interstitial_ready() -> bool:
	if bridge == null or not enabled:
		return false
	return bridge.isInterstitialReady()


func show_interstitial() -> bool:
	if bridge == null or not enabled:
		return false
	var shown := bool(bridge.showInterstitial())
	if not shown:
		notice.emit("Ad is loading. Try again in a moment.", "info", Kit.MUTED)
	return shown


func is_rewarded_ready() -> bool:
	if bridge == null or not enabled:
		return false
	return bridge.isRewardedReady()


func show_rewarded() -> bool:
	if bridge == null or not enabled:
		notice.emit("Ads are not available right now.", "warning", Kit.MUTED)
		return false
	if not bridge.isRewardedReady():
		bridge.loadRewarded()
		notice.emit("Rewarded ad is loading. Try again in a moment.", "hourglass", Kit.MUTED)
		return false
	rewarded_pending = bool(bridge.showRewarded())
	if rewarded_pending:
		_reward_ticks = 0
		_reward_timer.start()
	return rewarded_pending


func _poll_reward() -> void:
	if bridge == null:
		_reward_timer.stop()
		rewarded_pending = false
		return
	_reward_ticks += 1
	if bridge.consumeReward():
		_reward_timer.stop()
		rewarded_pending = false
		reward_earned.emit()
		return
	if _reward_ticks > 120:
		_reward_timer.stop()
		rewarded_pending = false


func get_banner_height() -> float:
	return BANNER_HEIGHT if banner_visible else 0.0


func status_text() -> String:
	if not OS.has_feature("android"):
		return "Ads appear in the Android build only."
	if not available:
		return last_error if not last_error.is_empty() else "AdMob is unavailable."
	if not enabled:
		return "Ads are off while you are ad-free."
	return "Ads are active · remove them permanently from Settings"
