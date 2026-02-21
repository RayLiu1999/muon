# Muon 專案教學 (3)：音訊播放與背景控制

在音樂播放器中，最難搞的就是「背景播放」和「狀態同步」。這篇我們會說明 Muon 是如何處理這兩大魔王。

---

## 1. 為什麼播放音樂這麼麻煩？

如果只是要在 App 畫面上放一個播放按鈕，按下就有聲音，那是很簡單的（只需要 `just_audio`）。

但真正的音樂播放器需要：

1. **退到背景不會被系統殺掉**。
2. **在手機的鎖定畫面 / 下拉通知列，能顯示封面、標題、和控制按鈕**。
3. **耳機線控、藍牙耳機的操作要能連動**。
4. **App 畫面上的進度條、播放按鈕，必須隨時跟背景的真實狀態同步**。

為了解決這些問題，我們引進了 `audio_service` 這個強大的機制。

---

## 2. 認識 AppAudioHandler

在 `lib/audio/audio_handler.dart` 裡，我們寫了一個繼承自 `BaseAudioHandler` 的類別，叫做 `AppAudioHandler`。

把它想像成一個「轉接頭」：

- 它裡面包了一個實際會發出聲音的播放器 (`just_audio` 的 `AudioPlayer`)。
- 它向外（對 Android/iOS 系統，以及對我們自己的 UI）廣播目前的狀態：**現在播哪首？進度到哪？是播放還是暫停？**

### 播放命令的傳遞

當使用者在耳機上按下「下一首」，或者在通知列按「暫停」時，系統會把這個指令丟給 `audio_service`，然後觸發我們寫的 `skipToNext()` 或是 `pause()`。

### 狀態廣播

當 `just_audio` 底層播完一首歌、或是載入緩衝時，我們的 `AppAudioHandler` 會把這些資訊打包成一個 `PlaybackState`（播放狀態），廣播給系統和 UI。

---

## 3. 在 Android 上的血淚設定

Android 對於「會在背景一直佔用資源」的 App 給予非常嚴格的限制。為了讓 Muon 能夠順利在背景唱歌，我們在原生層（Android 的資料夾裡）做了兩件事：

1. **宣告權限 (AndroidManifest.xml)**：
   我們告訴系統：「這是一個媒體播放用的前景服務 (Foreground Service)」。我們也要求了保持喚醒 (`WAKE_LOCK`) 和網路 (`INTERNET`) 權限。

   ```xml
   <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
   <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
   ```

2. **註冊服務元件**：
   我們在 Manifest 檔案中註冊了系統要求用來接聽耳機按鈕和通知列操作的 Receiver。

3. **提供 FlutterEngine給背景**：
   因為退到背景後，畫面的那一個 Activity 可能會被暫停。我們必須讓原生的 `MainActivity.kt` 把 FlutterEngine 借給 `audio_service` 的背景服務使用。這也是為什麼啟動時如果不加上 `provideFlutterEngine`，App 就會閃退的原因。

---

## 4. 狀態如何流進 UI 裡？ (Audio Provider)

有了 Handler，那首頁或播放器要怎麼知道現在播哪首？

我們在 `lib/presentation/providers/audio_provider.dart` 裡，寫了 8 個專門提供狀態的 Stream Provider。例如：

```dart
/// 當前播放位置 Provider（串流）
@riverpod
Stream<Duration> currentPosition(Ref ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.positionStream;
}
```

這個 Stream 每幾毫秒都會吐出新的進度（Duration）。而在 UI 上，例如全螢幕播放器 (`FullScreenPlayerPage`)，我們只要 `ref.watch(currentPositionProvider)`，進度條就會自己跟著動起來了！

**不用寫任何 `setState`，也不用管生命週期。這就是 Riverpod 帶來的魔法。**

---

**下一篇，我們來看看 UI 架構：GoRouter 與各種 Provider 是如何整合在一起的。**
