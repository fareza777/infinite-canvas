class_name PdfTool
extends RefCounted

static var last_error := ""


static func available() -> bool:
	return OS.has_feature("android") and ClassDB.class_exists("JavaClassWrapper")


static func rasterize(pdf_path: String, out_dir: String, scale := 1.7, max_pages := 32) -> Array:
	last_error = ""
	if not available():
		last_error = "PDF rasterisation requires the Android build."
		return []
	if not FileAccess.file_exists(pdf_path):
		last_error = "PDF file could not be opened."
		return []
	DirAccess.make_dir_recursive_absolute(out_dir)
	var output_files := []
	var abs_pdf := ProjectSettings.globalize_path(pdf_path)
	var abs_out := ProjectSettings.globalize_path(out_dir)
	var wrapper = JavaClassWrapper
	var bridge = wrapper.wrap("com.godot.game.PdfBridge")
	var bridge_exception = wrapper.get_exception()
	if bridge != null and bridge_exception == null and bridge.has_java_method("render"):
		var raw = bridge.render(abs_pdf, abs_out, scale, max_pages)
		var raw_exception = wrapper.get_exception()
		if raw_exception != null:
			last_error = "PDF bridge failed: " + str(raw_exception)
			return []
		var text := str(raw)
		if text.begins_with("ERR:"):
			last_error = text.trim_prefix("ERR:").strip_edges()
			return []
		if text.begins_with("OK"):
			var lines := text.split("\n", false)
			var user_root := ProjectSettings.globalize_path("user://").replace("\\", "/")
			for i in range(1, lines.size()):
				var absolute := str(lines[i]).strip_edges().replace("\\", "/")
				if absolute.is_empty():
					continue
				if absolute.begins_with(user_root):
					output_files.append("user://" + absolute.trim_prefix(user_root))
				else:
					output_files.append(absolute)
			if output_files.is_empty():
				last_error = "The PDF bridge rendered no pages."
			return output_files
	var File = wrapper.wrap("java.io.File")
	var PFD = wrapper.wrap("android.os.ParcelFileDescriptor")
	var PdfRenderer = wrapper.wrap("android.graphics.pdf.PdfRenderer")
	var Bitmap = wrapper.wrap("android.graphics.Bitmap")
	var BitmapConfig = wrapper.wrap("android.graphics.Bitmap$Config")
	var Canvas = wrapper.wrap("android.graphics.Canvas")
	var Matrix = wrapper.wrap("android.graphics.Matrix")
	var CompressFormat = wrapper.wrap("android.graphics.Bitmap$CompressFormat")
	var FileOutputStream = wrapper.wrap("java.io.FileOutputStream")
	var file = null
	var pfd = null
	var renderer = null
	var fos = null
	var page = null
	var bitmap = null
	var config = null
	var fmt = null
	var failed := false
	file = File.File(abs_pdf)
	var exception = wrapper.get_exception()
	if exception != null:
		last_error = "Could not open PDF: " + str(exception)
		return []
	pfd = PFD.open(file, 1)
	exception = wrapper.get_exception()
	if exception != null or pfd == null:
		last_error = "Could not read PDF: " + str(exception)
		return []
	renderer = PdfRenderer.PdfRenderer(pfd)
	exception = wrapper.get_exception()
	if exception != null or renderer == null:
		last_error = "PDF renderer unavailable: " + str(exception)
		return []
	var page_count: int = renderer.getPageCount()
	if page_count <= 0:
		last_error = "This PDF has no pages."
		return []
	page_count = mini(page_count, max_pages)
	config = BitmapConfig.valueOf("ARGB_8888")
	if config == null:
		config = BitmapConfig.ARGB_8888
	fmt = CompressFormat.valueOf("PNG")
	if fmt == null:
		fmt = CompressFormat.PNG
	var stamp := str(int(Time.get_unix_time_from_system()))
	for i in range(page_count):
		page = renderer.openPage(i)
		exception = wrapper.get_exception()
		if exception != null or page == null:
			failed = true
			break
		var width: int = page.getWidth()
		var height: int = page.getHeight()
		var scaled_w := maxi(1, int(width * scale))
		var scaled_h := maxi(1, int(height * scale))
		bitmap = Bitmap.createBitmap(scaled_w, scaled_h, config)
		exception = wrapper.get_exception()
		if exception != null or bitmap == null:
			failed = true
			break
		bitmap.eraseColor(-1)
		var canvas = Canvas.Canvas(bitmap)
		var matrix = Matrix.Matrix()
		matrix.setScale(scale, scale)
		page.render(canvas, null, matrix, 1)
		exception = wrapper.get_exception()
		if exception != null:
			failed = true
			break
		var target := "%s/%s_page_%03d.png" % [out_dir, stamp, i + 1]
		var out_file = File.File(ProjectSettings.globalize_path(target))
		fos = FileOutputStream.FileOutputStream(out_file)
		bitmap.compress(fmt, 100, fos)
		exception = wrapper.get_exception()
		if exception != null:
			failed = true
			break
		fos.close()
		output_files.append(target)
		page.close()
		page = null
	if page != null:
		page.close()
	if renderer != null:
		renderer.close()
	if pfd != null:
		pfd.close()
	if failed:
		last_error = "One or more PDF pages could not be rendered."
		return []
	if output_files.is_empty():
		last_error = "No pages were rendered."
	return output_files
