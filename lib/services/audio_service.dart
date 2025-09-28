import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  // Play notification sound
  Future<void> playNotificationSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      _isPlaying = true;
      
      // Auto-stop after 3 seconds if still playing
      Future.delayed(const Duration(seconds: 3), () {
        if (_isPlaying) {
          stopSound();
        }
      });
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
      // Fallback to system sound
      await _playSystemSound();
    }
  }

  // Play alarm sound
  Future<void> playAlarmSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
      // Fallback to system sound
      await _playSystemSound();
    }
  }

  // Stop any playing sound
  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error stopping sound: $e');
    }
  }

  // Play system notification sound as fallback
  Future<void> _playSystemSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('Error playing system sound: $e');
    }
  }

  // Play custom sound from asset
  Future<void> playCustomSound(String assetPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error playing custom sound: $e');
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  // Dispose audio player
  void dispose() {
    _audioPlayer.dispose();
  }
}