class_name SmartEngine
extends RefCounted

const STOPWORDS := {
	"the": true, "and": true, "for": true, "are": true, "but": true, "not": true, "you": true,
	"with": true, "this": true, "that": true, "from": true, "have": true, "has": true, "was": true,
	"will": true, "can": true, "all": true, "any": true, "our": true, "out": true, "your": true,
	"about": true, "into": true, "than": true, "then": true, "them": true, "their": true, "there": true,
	"what": true, "when": true, "where": true, "which": true, "while": true, "who": true, "why": true,
	"how": true, "its": true, "it's": true, "also": true, "just": true, "more": true, "most": true,
	"some": true, "such": true, "very": true, "make": true, "made": true, "use": true, "using": true,
	"one": true, "two": true, "get": true, "got": true, "new": true, "like": true, "need": true,
	"should": true, "would": true, "could": true, "does": true, "did": true, "doing": true,
	"yang": true, "dan": true, "untuk": true, "dengan": true, "dari": true, "ini": true, "itu": true,
	"ada": true, "akan": true, "tidak": true, "bisa": true, "juga": true, "atau": true, "pada": true,
	"ke": true, "di": true, "sebagai": true, "adalah": true, "dalam": true, "oleh": true, "agar": true,
	"saya": true, "kita": true, "kami": true, "mereka": true, "anda": true, "kamu": true, "dia": true,
	"buat": true, "membuat": true, "harus": true, "sudah": true, "belum": true, "masih": true,
	"lebih": true, "sangat": true, "banyak": true, "semua": true, "setiap": true, "satu": true,
	"dua": true, "tiga": true, "jadi": true, "kalau": true, "karena": true, "supaya": true,
	"contoh": true, "nya": true, "pun": true, "lah": true, "kah": true, "ku": true, "mu": true,
}


static func tokenize(text: String) -> Array:
	var clean := text.to_lower()
	for ch in [".", ",", "!", "?", ";", ":", "\n", "\t", "\"", "'", "(", ")", "[", "]", "{", "}", "—", "–", "/", "\\", "|", "@", "#", "$", "%", "^", "&", "*", "+", "=", "<", ">", "~", "_"]:
		clean = clean.replace(ch, " ")
	var words := clean.split(" ", false)
	var result := []
	for word in words:
		var w := word.strip_edges()
		if w.length() >= 3 and not STOPWORDS.has(w) and not w.is_valid_int():
			result.append(w)
	return result


static func term_frequency(text: String) -> Dictionary:
	var tf := {}
	for token in tokenize(text):
		tf[token] = int(tf.get(token, 0)) + 1
	return tf


static func item_text(item: Dictionary) -> String:
	var props: Dictionary = item.get("props", {})
	var parts := [str(props.get("title", "")), str(props.get("body", "")), str(props.get("caption", ""))]
	var tags: Array = props.get("tags", [])
	if not tags.is_empty():
		parts.append(" ".join(tags))
	return " ".join(parts)


static func keywords(text: String, limit := 6) -> Array:
	var tf := term_frequency(text)
	var entries := tf.keys()
	entries.sort_custom(func(a, b): return int(tf[a]) > int(tf[b]))
	var result := []
	for word in entries:
		result.append(str(word))
		if result.size() >= limit:
			break
	return result


static func board_documents(project: CanvasProject) -> Array:
	var docs := []
	for item in project.items:
		var type: String = item.get("type", "")
		if type in ["note", "text", "frame"]:
			var text := item_text(item)
			if text.strip_edges().length() >= 3:
				docs.append({"id": item.get("id", ""), "text": text, "item": item})
		elif type == "image" or type == "pdf":
			var caption := str(item.get("props", {}).get("caption", ""))
			if caption.strip_edges().length() >= 3:
				docs.append({"id": item.get("id", ""), "text": caption, "item": item})
	return docs


static func build_vectors(docs: Array) -> Dictionary:
	var df := {}
	var tokenized := []
	for doc in docs:
		var tf := term_frequency(str(doc.get("text", "")))
		tokenized.append(tf)
		for token in tf.keys():
			df[token] = int(df.get(token, 0)) + 1
	var n := maxf(1.0, float(docs.size()))
	var vectors := []
	for tf in tokenized:
		var vec := {}
		var length := 0.0
		for token in tf.keys():
			var weight := float(tf[token]) * log(1.0 + n / float(df[token]))
			vec[token] = weight
			length += weight * weight
		length = sqrt(length)
		if length > 0.0:
			for token in vec.keys():
				vec[token] = float(vec[token]) / length
		vectors.append(vec)
	return {"vectors": vectors, "df": df, "n": n}


static func cosine(a: Dictionary, b: Dictionary) -> float:
	if a.is_empty() or b.is_empty():
		return 0.0
	var score := 0.0
	var small := a
	var large := b
	if a.size() > b.size():
		small = b
		large = a
	for token in small.keys():
		if large.has(token):
			score += float(small[token]) * float(large[token])
	return clampf(score, 0.0, 1.0)


static func suggest_connections(project: CanvasProject, threshold := 0.16, max_pairs := 24) -> Array:
	var docs := board_documents(project)
	if docs.size() < 2:
		return []
	var vectors: Array = build_vectors(docs)["vectors"]
	var suggestions := []
	for i in range(docs.size()):
		for j in range(i + 1, docs.size()):
			var a_id: String = docs[i].get("id", "")
			var b_id: String = docs[j].get("id", "")
			if a_id == b_id or not project.connector_between(a_id, b_id).is_empty():
				continue
			var score := cosine(vectors[i], vectors[j])
			if score >= threshold:
				var shared := _shared_keywords(docs[i], docs[j])
				suggestions.append({
					"from": a_id,
					"to": b_id,
					"score": score,
					"reason": ", ".join(shared.slice(0, 3)),
					"label": str(shared[0]) if not shared.is_empty() else "related",
				})
	suggestions.sort_custom(func(a, b): return float(a["score"]) > float(b["score"]))
	if suggestions.size() > max_pairs:
		suggestions = suggestions.slice(0, max_pairs)
	return suggestions


static func _shared_keywords(a: Dictionary, b: Dictionary) -> Array:
	var ka := keywords(str(a.get("text", "")), 10)
	var kb := keywords(str(b.get("text", "")), 10)
	var result := []
	for k in ka:
		if k in kb and not k in result:
			result.append(k)
	return result


static func clusters(project: CanvasProject) -> Array:
	var docs := board_documents(project)
	var df := {}
	var doc_tokens := []
	for doc in docs:
		var tf := term_frequency(str(doc.get("text", "")))
		doc_tokens.append(tf)
		for token in tf.keys():
			df[token] = int(df.get(token, 0)) + 1
	var candidate := []
	for token in df.keys():
		if int(df[token]) >= 2:
			candidate.append({"keyword": token, "count": int(df[token]), "docs": []})
	candidate.sort_custom(func(a, b): return int(a["count"]) > int(b["count"]))
	candidate = candidate.slice(0, 8)
	for group in candidate:
		for i in range(docs.size()):
			if doc_tokens[i].has(group["keyword"]):
				group["docs"].append(docs[i].get("id", ""))
	var used := {}
	var result := []
	for group in candidate:
		var fresh := []
		for id in group["docs"]:
			if not used.has(id):
				fresh.append(id)
		if fresh.size() >= 2:
			for id in fresh:
				used[id] = true
			result.append({"keyword": group["keyword"], "ids": fresh})
	var leftovers := []
	for doc in docs:
		if not used.has(doc.get("id", "")):
			leftovers.append(doc.get("id", ""))
	if not leftovers.is_empty():
		result.append({"keyword": "unsorted", "ids": leftovers})
	return result


static func summarize(project: CanvasProject, max_sentences := 7) -> String:
	var docs := board_documents(project)
	if docs.is_empty():
		return ""
	var all_text := ""
	for doc in docs:
		all_text += str(doc.get("text", "")) + ". "
	var sentences := _split_sentences(all_text)
	if sentences.is_empty():
		return ""
	var keyword_scores := {}
	var kw := keywords(all_text, 16)
	for i in range(kw.size()):
		keyword_scores[kw[i]] = 16.0 - float(i)
	var ranked := []
	for sentence in sentences:
		var score := 0.0
		var tokens := tokenize(sentence)
		for token in tokens:
			score += float(keyword_scores.get(token, 0.0))
		score = score / sqrt(maxf(4.0, float(tokens.size())))
		score += minf(3.0, float(sentence.length()) / 120.0)
		ranked.append({"sentence": sentence.strip_edges(), "score": score})
	ranked.sort_custom(func(a, b): return float(a["score"]) > float(b["score"]))
	var chosen := []
	var seen := {}
	for entry in ranked:
		if chosen.size() >= max_sentences:
			break
		var sentence := str(entry["sentence"])
		if sentence.length() < 12 or seen.has(sentence.to_lower()):
			continue
		seen[sentence.to_lower()] = true
		chosen.append(sentence)
	return "\n".join(chosen)


static func _split_sentences(text: String) -> Array:
	var result := []
	var current := ""
	for ch in text:
		current += ch
		if ch in [".", "!", "?", "\n"]:
			var s := current.strip_edges()
			if s.length() > 3:
				result.append(s)
			current = ""
	if current.strip_edges().length() > 3:
		result.append(current.strip_edges())
	return result


static func top_keywords(project: CanvasProject, limit := 12) -> Array:
	var all_text := ""
	for doc in board_documents(project):
		all_text += str(doc.get("text", "")) + " "
	var tf := term_frequency(all_text)
	var entries := tf.keys()
	entries.sort_custom(func(a, b): return int(tf[a]) > int(tf[b]))
	var result := []
	for word in entries:
		result.append({"word": str(word), "count": int(tf[word])})
		if result.size() >= limit:
			break
	return result


static func next_steps(project: CanvasProject) -> Array:
	var stats := project.stats()
	var steps := []
	if stats["notes"] == 0:
		steps.append("Capture the core idea as a note")
	if stats["frames"] < 3:
		steps.append("Sketch at least three storyboard frames")
	if stats["connectors"] < int(stats["items"] / 2.0):
		steps.append("Connect related ideas with smart connectors")
	if stats["models"] == 0:
		steps.append("Place a 3D object to give the board depth")
	if project.bookmarks.size() < 2:
		steps.append("Save two camera bookmarks for quick navigation")
	if steps.is_empty():
		steps.append("Present the board, then export a PNG snapshot")
	return steps


static func tidy_positions(project: CanvasProject, origin := Vector3.ZERO) -> Dictionary:
	var positions := {}
	var docs := board_documents(project)
	var columns := 3
	var cell := Vector2(7.2, -6.0)
	var index := 0
	for doc in docs:
		var item: Dictionary = doc.get("item", {})
		if item.get("parent", "") != "":
			continue
		var col := index % columns
		var row := int(index / columns)
		positions[doc.get("id", "")] = origin + Vector3(float(col) * cell.x, float(row) * cell.y, 0.0)
		index += 1
	return positions


static func cluster_positions(project: CanvasProject, origin := Vector3.ZERO) -> Dictionary:
	var groups := clusters(project)
	var positions := {}
	var cluster_gap := 12.0
	var col_width := 8.0
	var x := origin.x
	for group in groups:
		var ids: Array = group.get("ids", [])
		var y := origin.y + 2.0
		for id in ids:
			positions[id] = Vector3(x, y, 0.0)
			y -= 4.2
		x += col_width + cluster_gap
	return positions
