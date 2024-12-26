package com.xbin.hand_mediapipe_plugin;

import android.app.Activity;
import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class HandMediapipeViewFactory extends PlatformViewFactory {


    @NonNull
    private Activity activity;

    @NonNull
    private EventChannel.EventSink eventSink;
    public HandMediapipeViewFactory(Activity activity,EventChannel.EventSink eventSink) {
        super(StandardMessageCodec.INSTANCE);
        this.activity =activity;
        this.eventSink = eventSink;
    }

    @NonNull
    @Override
    public PlatformView create(Context context, int id, Object args) {
        return new HandMediapipeView(context,activity,eventSink);
    }



}
