package com.xbin.hand_mediapipe_plugin;


import android.app.Activity;

import androidx.annotation.NonNull;

import com.google.mediapipe.components.PermissionHelper;

import java.util.Objects;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformViewRegistry;


/** HandMediapipePlugin */
public class HandMediapipePlugin implements FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

  private MethodChannel channel;
  private FlutterPluginBinding pluginBinding;

  public EventChannel.EventSink eventSink;

  public static final String eventChannelName = "com.xbin/hand_landmarks";

  private BinaryMessenger binaryMessenger;

  private HandMediapipeViewFactory handMediapipeViewFactory;

  private Activity activity;


//  使用插件的时候会触发
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {


    this.pluginBinding = flutterPluginBinding;

    this.binaryMessenger = flutterPluginBinding.getBinaryMessenger();
    new EventChannel(binaryMessenger,eventChannelName).setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object arguments, EventChannel.EventSink events) {

        eventSink = events;
        handMediapipeViewFactory = new HandMediapipeViewFactory(activity,events);
        // Register the custom PlatformView.
        pluginBinding
                .getPlatformViewRegistry()
                .registerViewFactory("hand_mediapipe_view", handMediapipeViewFactory);
      }

      @Override
      public void onCancel(Object arguments) {
        eventSink = null;
      }
    });
    // Method channel for non-UI-related functions.
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "hand_mediapipe_plugin");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (channel != null) {
      channel.setMethodCallHandler(null);
      channel = null;
    }
    pluginBinding = null;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    this.activity = binding.getActivity();
    PermissionHelper.checkAndRequestCameraPermissions(activity);


  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {

  }

}
