package com.xbin.hand_mediapipe_plugin;

import android.app.Activity;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.FrameLayout;

import androidx.annotation.Nullable;
import android.util.Log;

import com.google.mediapipe.formats.proto.LandmarkProto;
import com.google.mediapipe.solutioncore.CameraInput;
import com.google.mediapipe.solutioncore.SolutionGlSurfaceView;
import com.google.mediapipe.solutions.hands.HandLandmark;
import com.google.mediapipe.solutions.hands.Hands;
import com.google.mediapipe.solutions.hands.HandsOptions;
import com.google.mediapipe.solutions.hands.HandsResult;
import android.graphics.Bitmap;
import android.graphics.Matrix;

import androidx.exifinterface.media.ExifInterface;
import com.google.mediapipe.formats.proto.LandmarkProto.NormalizedLandmark;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.Objects;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

// 一个演示组件
public class HandMediapipeView implements PlatformView  {

    private static final String TGA = "Hand Mediapipe Plugin";

    private final FrameLayout rootView;
    private Hands hands;
// 摄像头
    private CameraInput cameraInput;

    private long fiveGestureTime =  -1;

    private long fistGestureTime = -1;

    private long takeGestureTime = -1;
    private long lastTakeGestureTime = -1;

    private long putGestureTime = -1;

    private Activity activity;
    private SolutionGlSurfaceView<HandsResult> glSurfaceView;

    private Handler uiThreadHandler = new Handler(Looper.getMainLooper());

    private EventChannel.EventSink eventSink;
    public HandMediapipeView(Context context,Activity activity,EventChannel.EventSink eventSink) {
        rootView = new FrameLayout(context);
        this.activity = activity;
        this.eventSink = eventSink;

        setupMediaPipe(context);
    }

    @SuppressWarnings("NewApi")
    private void setupMediaPipe(Context context) {
        if (context == null) {
            Log.e("setupMediaPipe", "Context is null");
            return;
        }
        hands = new Hands(context, HandsOptions.builder().setRunOnGpu(true).build());

        // 在请求权限后启动相机
        glSurfaceView = new SolutionGlSurfaceView<>(context, hands.getGlContext(), hands.getGlMajorVersion());
        glSurfaceView.post(this::startCamera);
        glSurfaceView.setSolutionResultRenderer(new HandsResultGlRenderer());
        glSurfaceView.setRenderInputImage(true);
//        启动摄像头并且发送图片给模型处理
        cameraInput = new CameraInput(activity);
        cameraInput.setNewFrameListener(textureFrame -> hands.send(textureFrame));

        hands.setResultListener(handsResult -> {
//            logWristLandmark(handsResult, false);
            glSurfaceView.setRenderData(handsResult);
            glSurfaceView.requestRender();
            uiThreadHandler.post(() -> {
                if (eventSink != null && !Objects.isNull(handsResult)) {

                        int numHands = handsResult.multiHandLandmarks().size();
                        if (numHands>0){
                            String result = gestureDeter(handsResult);
                            long currentTime = System.currentTimeMillis();
                            if ("FIVE".equals(result)) {
                                // 检测到 "巴掌"
                                if (fistGestureTime > 0 && (currentTime - fistGestureTime <= 3000)) {
                                    // 在 3 秒内从 "巴掌" -> "拳头" 检测到“放的动作”
                                    result = "put";
                                    fistGestureTime = -1; // 重置时间戳
                                }
                                // 更新巴掌的时间戳
                                fiveGestureTime = currentTime;
                            } else if ("FIST".equals(result)) {
                                // 检测到 "拳头"
                                if (fiveGestureTime > 0 && (currentTime - fiveGestureTime <= 3000)) {
                                    // 在 3 秒内从 "巴掌" -> "拳头" 检测到“拿的动作”
                                    result = "take";                                  
                                    fiveGestureTime = -1; // 重置时间戳
                                }
                                // 更新拳头的时间戳
                                fistGestureTime = currentTime;
                            } else {
                                // 忽略其他手势
                                if (currentTime - fiveGestureTime > 3000) {
                                    fiveGestureTime = -1; 
                                }
                                if (currentTime - fistGestureTime > 3000) {
                                    fistGestureTime = -1; 
                                }
                            }
                                // 发送手势结果
                                eventSink.success(result);

                        }

                }
            });
        });

        if (rootView.indexOfChild(glSurfaceView) == -1) {
            rootView.removeAllViewsInLayout();
            rootView.addView(glSurfaceView);
        }
        glSurfaceView.setVisibility(View.VISIBLE);
        rootView.requestLayout();
    }

    private void startCamera() {
        cameraInput.start(
                activity,
                hands.getGlContext(),
                CameraInput.CameraFacing.FRONT,
                glSurfaceView.getWidth(),
                glSurfaceView.getHeight());
    }


    @Nullable
    @Override
    public View getView() {
        return rootView;
    }

    @Override
    public void dispose() {
        if (hands != null) hands.close();
        if (glSurfaceView != null) glSurfaceView.setVisibility(View.GONE);
    }



    // Run the pipeline and the model inference on GPU or CPU.
    private static final boolean RUN_ON_GPU = true;



//    此方法的作用是根据图像视图（imageView）的宽高比例，缩放原始的 Bitmap，使其适应显示区域的尺寸，并保持图像的纵横比。
//    此方法用于根据图像的 EXIF 数据（图像的方向信息）旋转图像，确保图像正确显示。
    private Bitmap rotateBitmap(Bitmap inputBitmap, InputStream imageData) throws IOException {
        int orientation =
                new ExifInterface(imageData)
                        .getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
        if (orientation == ExifInterface.ORIENTATION_NORMAL) {
            return inputBitmap;
        }
        Matrix matrix = new Matrix();
        switch (orientation) {
            case ExifInterface.ORIENTATION_ROTATE_90:
                matrix.postRotate(90);
                break;
            case ExifInterface.ORIENTATION_ROTATE_180:
                matrix.postRotate(180);
                break;
            case ExifInterface.ORIENTATION_ROTATE_270:
                matrix.postRotate(270);
                break;
            default:
                matrix.postRotate(0);
        }
        return Bitmap.createBitmap(
                inputBitmap, 0, 0, inputBitmap.getWidth(), inputBitmap.getHeight(), matrix, true);
    }



//    打印手掌坐标
    private void logWristLandmark(HandsResult result, boolean showPixelValues) {
        if (result.multiHandLandmarks().isEmpty()) {
            return;
        }
        NormalizedLandmark wristLandmark =
                result.multiHandLandmarks().get(0).getLandmarkList().get(HandLandmark.WRIST);
        // For Bitmaps, show the pixel values. For texture inputs, show the normalized coordinates.
        if (showPixelValues) {
            int width = result.inputBitmap().getWidth();
            int height = result.inputBitmap().getHeight();
            Log.i(
                    TGA,
                    String.format(
                            "MediaPipe Hand wrist coordinates (pixel values): x=%f, y=%f",
                            wristLandmark.getX() * width, wristLandmark.getY() * height));
        } else {
            Log.i(
                    TGA,
                    String.format(
                            "MediaPipe Hand wrist normalized coordinates (value range: [0, 1]): x=%f, y=%f",
                            wristLandmark.getX(), wristLandmark.getY()));
        }
        if (result.multiHandWorldLandmarks().isEmpty()) {
            return;
        }
        LandmarkProto.Landmark wristWorldLandmark =
                result.multiHandWorldLandmarks().get(0).getLandmarkList().get(HandLandmark.WRIST);
        Log.i(
                TGA,
                String.format(
                        "MediaPipe Hand wrist world coordinates (in meters with the origin at the hand's"
                                + " approximate geometric center): x=%f m, y=%f m, z=%f m",
                        wristWorldLandmark.getX(), wristWorldLandmark.getY(), wristWorldLandmark.getZ()));
    }

    public String renderResult(HandsResult result) throws JSONException {
        JSONObject jsonOutput = new JSONObject();
        JSONArray leftHandCoordinates = new JSONArray();
        JSONArray rightHandCoordinates = new JSONArray();

        int numHands = result.multiHandLandmarks().size();
        for (int i = 0; i < numHands; ++i) {
            boolean isLeftHand = result.multiHandedness().get(i).getLabel().equals("Left");
            JSONArray targetArray = isLeftHand ? leftHandCoordinates : rightHandCoordinates;

            // 遍历每个关键点，将其坐标加入 JSON 数组
            for (NormalizedLandmark landmark : result.multiHandLandmarks().get(i).getLandmarkList()) {
                JSONObject coordinate = new JSONObject();
                coordinate.put("x", landmark.getX());
                coordinate.put("y", landmark.getY());
                coordinate.put("z", landmark.getZ());
                targetArray.put(coordinate);
            }
        }

        // 将左右手坐标放入最终的 JSON 对象
        jsonOutput.put("leftHand", leftHandCoordinates);
        jsonOutput.put("rightHand", rightHandCoordinates);

        // 打印结果
        return(jsonOutput.toString());
    }


    // 判断某个手指是否张开
    private static boolean fingerIsOpen(float pseudoFixKeyPoint, float point1, float point2) {
        return point1 > pseudoFixKeyPoint && point2 < pseudoFixKeyPoint;
    }

    private static boolean thumbIsOpen(List<NormalizedLandmark> landmarks) {
        return fingerIsOpen(landmarks.get(3).getX(), landmarks.get(2).getX(), landmarks.get(4).getX());
    }

    private static boolean firstFingerIsOpen(List<NormalizedLandmark> landmarks) {
        return fingerIsOpen(landmarks.get(7).getY(), landmarks.get(6).getY(), landmarks.get(8).getY());
    }

    private static boolean secondFingerIsOpen(List<NormalizedLandmark> landmarks) {
        return fingerIsOpen(landmarks.get(11).getY(), landmarks.get(10).getY(), landmarks.get(12).getY());
    }

    private static boolean thirdFingerIsOpen(List<NormalizedLandmark> landmarks) {
        return fingerIsOpen(landmarks.get(15).getY(), landmarks.get(14).getY(), landmarks.get(16).getY());
    }

    private static boolean fourthFingerIsOpen(List<NormalizedLandmark> landmarks) {
        return fingerIsOpen(landmarks.get(19).getY(), landmarks.get(18).getY(), landmarks.get(20).getY());
    }

    private static double getEuclideanDistance(float x1, float y1, float x2, float y2) {
        return Math.sqrt(Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2));
    }

    private static boolean isThumbNearFirstFinger(NormalizedLandmark thumb, NormalizedLandmark index) {
        return getEuclideanDistance(thumb.getX(), thumb.getY(), index.getX(), index.getY()) < 0.1;
    }

    public String gestureDeter(HandsResult result) {

        int numHands = result.multiHandLandmarks().size();
        String gesture = "UNKNOWN";
        for (int i = 0; i < numHands; ++i) {
            boolean isLeftHand = "Left".equals(result.multiHandedness().get(i).getLabel());
            List<NormalizedLandmark> landmarks = result.multiHandLandmarks().get(i).getLandmarkList();

            if (!landmarks.isEmpty()) {
                boolean thumbIsOpen = thumbIsOpen(landmarks);
                boolean firstFingerIsOpen = firstFingerIsOpen(landmarks);
                boolean secondFingerIsOpen = secondFingerIsOpen(landmarks);
                boolean thirdFingerIsOpen = thirdFingerIsOpen(landmarks);
                boolean fourthFingerIsOpen = fourthFingerIsOpen(landmarks);

                if (thumbIsOpen && firstFingerIsOpen && secondFingerIsOpen && thirdFingerIsOpen && fourthFingerIsOpen) {
                    gesture = "FIVE";
                } else if (!thumbIsOpen && firstFingerIsOpen && secondFingerIsOpen && thirdFingerIsOpen && fourthFingerIsOpen) {
                    gesture = "FOUR";
                } else if (thumbIsOpen && firstFingerIsOpen && secondFingerIsOpen && !thirdFingerIsOpen && !fourthFingerIsOpen) {
                    gesture = "TREE";
                } else if (thumbIsOpen && firstFingerIsOpen && !secondFingerIsOpen && !thirdFingerIsOpen && !fourthFingerIsOpen) {
                    gesture = "TWO";
                } else if (!thumbIsOpen && firstFingerIsOpen && !secondFingerIsOpen && !thirdFingerIsOpen && !fourthFingerIsOpen) {
                    gesture = "ONE";
                } else if (!thumbIsOpen && firstFingerIsOpen && secondFingerIsOpen && !thirdFingerIsOpen && !fourthFingerIsOpen) {
                    gesture = "YEAH";
                } else if (!thumbIsOpen && firstFingerIsOpen && !secondFingerIsOpen && !thirdFingerIsOpen && fourthFingerIsOpen) {
                    gesture = "ROCK";
                } else if (thumbIsOpen && firstFingerIsOpen && !secondFingerIsOpen && !thirdFingerIsOpen && fourthFingerIsOpen) {
                    gesture = "SPIDERMAN";
//                    修改代码
                } else if (!thumbIsOpen && !firstFingerIsOpen && !secondFingerIsOpen && !thirdFingerIsOpen && !fourthFingerIsOpen) {
                    gesture = "FIST";
                } else if (!firstFingerIsOpen && secondFingerIsOpen && thirdFingerIsOpen && fourthFingerIsOpen && isThumbNearFirstFinger(landmarks.get(4), landmarks.get(8))) {
                    gesture = "OK";
                } else {
                    gesture = "UNKNOWN";
                }

            }

        }
        return (gesture);
    }


}
