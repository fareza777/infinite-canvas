package com.godot.game;

import android.content.Context;
import android.content.Intent;

public class ShareBridge {
    public static String share(String subject, String text) {
        try {
            Class<?> activityThreadClass = Class.forName("android.app.ActivityThread");
            Object app = activityThreadClass.getMethod("currentApplication").invoke(null);
            if (!(app instanceof Context)) {
                return "ERR: no application context";
            }
            Context context = (Context) app;
            Intent send = new Intent(Intent.ACTION_SEND);
            send.setType("text/plain");
            send.putExtra(Intent.EXTRA_SUBJECT, subject);
            send.putExtra(Intent.EXTRA_TEXT, text);
            Intent chooser = Intent.createChooser(send, subject);
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(chooser);
            return "OK";
        } catch (Throwable t) {
            return "ERR: " + t.getClass().getSimpleName() + ": " + t.getMessage();
        }
    }
}
