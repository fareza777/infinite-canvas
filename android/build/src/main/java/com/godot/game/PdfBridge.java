package com.godot.game;

import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.pdf.PdfRenderer;
import android.os.ParcelFileDescriptor;

import java.io.File;
import java.io.FileOutputStream;

/**
 * Small, dependency-free bridge for rasterising PDF pages with Android's platform renderer.
 * Called from GDScript through JavaClassWrapper. Returns:
 *   OK\n<absolute page path>\n<absolute page path>...
 * or
 *   ERR: <message>
 */
public final class PdfBridge {
    private PdfBridge() {}

    public static String render(String pdfPath, String outDir, float scale, int maxPages) {
        ParcelFileDescriptor pfd = null;
        PdfRenderer renderer = null;
        try {
            File dir = new File(outDir);
            if (!dir.isDirectory() && !dir.mkdirs()) {
                return "ERR: cannot create output directory";
            }
            File source = new File(pdfPath);
            if (!source.isFile()) {
                return "ERR: PDF file not found";
            }
            pfd = ParcelFileDescriptor.open(source, ParcelFileDescriptor.MODE_READ_ONLY);
            renderer = new PdfRenderer(pfd);
            int pageCount = renderer.getPageCount();
            if (pageCount <= 0) {
                return "ERR: PDF has no pages";
            }
            pageCount = Math.min(pageCount, Math.max(1, maxPages));
            float safeScale = Math.max(0.5f, Math.min(4.0f, scale));
            StringBuilder result = new StringBuilder("OK");
            String stamp = String.valueOf(System.currentTimeMillis());
            for (int i = 0; i < pageCount; i++) {
                PdfRenderer.Page page = null;
                Bitmap bitmap = null;
                FileOutputStream output = null;
                try {
                    page = renderer.openPage(i);
                    int width = Math.max(1, (int) (page.getWidth() * safeScale));
                    int height = Math.max(1, (int) (page.getHeight() * safeScale));
                    bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
                    bitmap.eraseColor(Color.WHITE);
                    Matrix matrix = new Matrix();
                    matrix.setScale(safeScale, safeScale);
                    page.render(bitmap, null, matrix, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY);
                    File target = new File(dir, stamp + "_page_" + (i + 1) + ".png");
                    output = new FileOutputStream(target);
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, output);
                    output.flush();
                    result.append('\n').append(target.getAbsolutePath());
                } finally {
                    if (output != null) {
                        try { output.close(); } catch (Exception ignored) {}
                    }
                    if (bitmap != null) {
                        bitmap.recycle();
                    }
                    if (page != null) {
                        page.close();
                    }
                }
            }
            return result.toString();
        } catch (Throwable error) {
            String message = error.getMessage();
            return "ERR: " + error.getClass().getSimpleName() + (message == null ? "" : (": " + message));
        } finally {
            if (renderer != null) {
                try { renderer.close(); } catch (Exception ignored) {}
            }
            if (pfd != null) {
                try { pfd.close(); } catch (Exception ignored) {}
            }
        }
    }
}
