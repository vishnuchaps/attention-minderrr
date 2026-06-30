import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> initialize() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.6);
    await _tts.setVolume(0.8);
    await _tts.setPitch(1.0);
  }

  Future<void> playAttentionAlert({
    String? customMessage,
    bool playSound = true,
    bool speakMessage = true,
  }) async {
    final message = customMessage ??
        "Please look at the screen to continue your treatment session.";

    if (playSound) {
      try {
        await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
      } catch (e) {
        print('Error playing alert sound: $e');
      }
    }

    if (speakMessage) {
      try {
        await _tts.speak(message);
      } catch (e) {
        print('Error speaking message: $e');
      }
    }
  }

  Future<void> playSessionComplete() async {
    await _tts.speak("Congratulations! You have completed your treatment session.");
  }

  Future<void> playEncouragement(int attentionScore) async {
    String message;

    if (attentionScore >= 90) {
      message = "Excellent focus! Keep up the great work!";
    } else if (attentionScore >= 70) {
      message = "Good job staying focused!";
    } else if (attentionScore >= 50) {
      message = "You're doing well. Try to maintain your focus.";
    } else {
      message = "Remember to look at the screen during your treatment.";
    }

    await _tts.speak(message);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}