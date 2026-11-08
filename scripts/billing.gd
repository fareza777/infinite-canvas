class_name Billing
extends Node

signal state_changed
signal notice(text: String, icon: String, color: Color)

const PRODUCT_REMOVE_ADS := "remove_ads"
const ENTITLEMENT_PATH := "user://entitlement.json"

var client: Node
var available := false
var connected := false
var ads_removed := false
var status := "idle"
var last_error := ""
var products: Array = []
var purchase_in_flight := false
var _details_received := 0
var _details_expected := 1
var _query_timer: Timer
var _entitlement: Dictionary = {}


func _ready() -> void:
	_load_entitlement()
	if OS.has_feature("android") and Engine.has_singleton("GodotGooglePlayBilling"):
		available = true
		_setup_client()
	else:
		available = false
		status = "unavailable"
		last_error = "Google Play Billing is only available in an Android build installed from Google Play."


func _setup_client() -> void:
	client = BillingClient.new()
	client.connected.connect(_on_connected)
	client.disconnected.connect(_on_disconnected)
	client.connect_error.connect(_on_connect_error)
	client.query_product_details_response.connect(_on_product_details)
	client.query_purchases_response.connect(_on_purchases)
	client.on_purchase_updated.connect(_on_purchase_updated)
	client.acknowledge_purchase_response.connect(_on_acknowledged)
	status = "connecting"
	_query_timer = Timer.new()
	_query_timer.one_shot = true
	_query_timer.wait_time = 15.0
	_query_timer.timeout.connect(_on_query_timeout)
	add_child(_query_timer)
	_query_timer.start()
	client.start_connection()
	state_changed.emit()


func _on_connected() -> void:
	connected = true
	status = "connected"
	last_error = ""
	_details_received = 0
	_details_expected = 1
	client.query_purchases(BillingClient.ProductType.INAPP)
	client.query_product_details(PackedStringArray([PRODUCT_REMOVE_ADS]), BillingClient.ProductType.INAPP)
	state_changed.emit()


func _on_disconnected() -> void:
	connected = false
	status = "disconnected"
	state_changed.emit()


func _on_connect_error(response_code: int, debug_message: String) -> void:
	connected = false
	status = "error"
	last_error = debug_message
	if _query_timer != null:
		_query_timer.stop()
	state_changed.emit()


func _on_query_timeout() -> void:
	if products.is_empty() and status == "connected":
		status = "no_products"
		last_error = "Google Play did not return the Remove Ads product. Check the product ID in Play Console."
		state_changed.emit()


func _on_product_details(response: Dictionary) -> void:
	_details_received += 1
	if int(response.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		last_error = str(response.get("debug_message", "Product query failed"))
		_finish_products()
		return
	var details: Array = response.get("product_details", [])
	for detail in details:
		var parsed := _parse_product(detail)
		if parsed.is_empty():
			continue
		var exists := false
		for existing in products:
			if str(existing.get("id", "")) == str(parsed.get("id", "")):
				exists = true
				break
		if not exists:
			products.append(parsed)
	_finish_products()


func _finish_products() -> void:
	if _query_timer != null:
		_query_timer.stop()
	if products.is_empty():
		status = "no_products"
		if last_error.is_empty():
			last_error = "Remove Ads was not found for this app. Configure remove_ads in Google Play Console."
	else:
		status = "ready"
	state_changed.emit()


func _parse_product(detail: Dictionary) -> Dictionary:
	var product_id := str(detail.get("product_id", detail.get("productId", "")))
	if product_id.is_empty():
		var ids: Array = detail.get("product_ids", detail.get("productIds", []))
		if not ids.is_empty():
			product_id = str(ids[0])
	if product_id != PRODUCT_REMOVE_ADS:
		return {}
	var price := str(detail.get("formatted_price", ""))
	var one_time: Dictionary = detail.get("one_time_purchase_offer_details", {})
	if price.is_empty() and not one_time.is_empty():
		price = str(one_time.get("formatted_price", ""))
	var title := str(detail.get("title", detail.get("name", "")))
	if title.is_empty():
		title = "Remove Ads"
	var description := str(detail.get("description", ""))
	if description.is_empty():
		description = "Remove banner, interstitial and rewarded ads permanently."
	return {
		"id": product_id,
		"type": "inapp",
		"title": title,
		"description": description,
		"price": price,
		"available": true,
		"raw": detail,
	}


func _on_purchases(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		return
	var purchases: Array = response.get("purchases", [])
	for purchase in purchases:
		_process_purchase(purchase)


func _on_purchase_updated(response: Dictionary) -> void:
	purchase_in_flight = false
	var code := int(response.get("response_code", -1))
	if code != BillingClient.BillingResponseCode.OK:
		if code == BillingClient.BillingResponseCode.USER_CANCELED:
			notice.emit("Purchase canceled", "info", Kit.MUTED)
		else:
			notice.emit("Purchase could not be completed", "warning", Kit.DANGER)
		state_changed.emit()
		return
	var purchases: Array = response.get("purchases", [])
	if purchases.is_empty():
		notice.emit("No purchase returned by Google Play", "info", Kit.MUTED)
		state_changed.emit()
		return
	for purchase in purchases:
		_process_purchase(purchase)


func _process_purchase(purchase: Dictionary) -> void:
	var ids: Array = purchase.get("product_ids", [])
	if not (PRODUCT_REMOVE_ADS in ids):
		return
	var state := int(purchase.get("purchase_state", 0))
	if state == BillingClient.PurchaseState.PENDING:
		notice.emit("Payment is pending approval", "pending", Kit.GOLD)
		return
	if state != BillingClient.PurchaseState.PURCHASED:
		return
	var token := str(purchase.get("purchase_token", ""))
	if not bool(purchase.get("is_acknowledged", false)) and client != null:
		client.acknowledge_purchase(token)
	_grant_remove_ads(token)


func _on_acknowledged(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		last_error = str(response.get("debug_message", "Acknowledge failed"))


func _grant_remove_ads(token: String) -> void:
	var was := ads_removed
	ads_removed = true
	_save_entitlement(true, PRODUCT_REMOVE_ADS, token)
	if not was:
		notice.emit("Ads removed. Thank you.", "block", Kit.GREEN)
	state_changed.emit()


func purchase_remove_ads() -> void:
	if client == null or not connected:
		notice.emit("Connect to Google Play to purchase Remove Ads", "info", Kit.MUTED)
		return
	if purchase_in_flight:
		return
	var found: Dictionary = {}
	for p in products:
		if str(p.get("id", "")) == PRODUCT_REMOVE_ADS:
			found = p
			break
	if found.is_empty():
		notice.emit("Remove Ads is not available from Google Play", "warning", Kit.DANGER)
		return
	purchase_in_flight = true
	var result: Dictionary = client.purchase(PRODUCT_REMOVE_ADS)
	if int(result.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		purchase_in_flight = false
		notice.emit("Unable to open Google Play checkout", "warning", Kit.DANGER)
		last_error = str(result.get("debug_message", ""))
		state_changed.emit()


func restore_purchases() -> void:
	if client == null or not connected:
		notice.emit("Google Play is not connected", "info", Kit.MUTED)
		return
	client.query_purchases(BillingClient.ProductType.INAPP)
	notice.emit("Checking your Google Play purchase", "restore", Kit.ACCENT)


func retry() -> void:
	if client != null:
		client.end_connection()
		client.queue_free()
		client = null
	products.clear()
	_load_entitlement()
	if OS.has_feature("android") and Engine.has_singleton("GodotGooglePlayBilling"):
		available = true
		_setup_client()
	else:
		available = false
		status = "unavailable"
		last_error = "Google Play Billing is only available in an Android build installed from Google Play."
		state_changed.emit()


func _load_entitlement() -> void:
	ads_removed = false
	_entitlement = {}
	if not FileAccess.file_exists(ENTITLEMENT_PATH):
		return
	var file := FileAccess.open(ENTITLEMENT_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_entitlement = parsed
	ads_removed = bool(parsed.get("remove_ads", false))


func _save_entitlement(active: bool, product_id: String, token: String) -> void:
	_entitlement = {
		"remove_ads": active,
		"product_id": product_id,
		"purchase_token": token,
		"updated": Time.get_unix_time_from_system(),
	}
	var file := FileAccess.open(ENTITLEMENT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_entitlement))
		file.close()


func get_price() -> String:
	for p in products:
		if str(p.get("id", "")) == PRODUCT_REMOVE_ADS:
			return str(p.get("price", ""))
	return ""


func get_product() -> Dictionary:
	for p in products:
		if str(p.get("id", "")) == PRODUCT_REMOVE_ADS:
			return p
	return {}


func get_status_text() -> String:
	match status:
		"unavailable":
			return last_error if not last_error.is_empty() else "Google Play Billing is not available in this build."
		"connecting":
			return "Connecting to Google Play…"
		"connected":
			return "Connected. Loading Remove Ads…"
		"ready":
			return "Google Play is ready."
		"no_products":
			return last_error if not last_error.is_empty() else "Remove Ads is not configured in Play Console."
		"error":
			return last_error if not last_error.is_empty() else "Could not connect to Google Play."
		"disconnected":
			return "Google Play connection was lost."
		_:
			return "Google Play Billing is unavailable."


func is_usable() -> bool:
	return available and connected and status == "ready"
