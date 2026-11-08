import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  AudioPlayer? _player;
  bool _isMuted = false;
  bool _initialized = false;
  bool _audioAvailable = true;

  bool get isMuted => _isMuted;

  AudioPlayer? _getPlayer() {
    if (!_audioAvailable) return null;
    if (_player == null) {
      try {
        _player = AudioPlayer();
      } catch (e) {
        _audioAvailable = false;
        return null;
      }
    }
    return _player;
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool('app_sound_muted') ?? false;
      _initialized = true;
    } catch (_) {}
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_sound_muted', _isMuted);
    } catch (_) {}
  }

  Future<void> _playSound(String assetName) async {
    if (_isMuted) return;
    try {
      final player = _getPlayer();
      if (player == null) return;
      await player.stop();
      await player.play(AssetSource('audio/$assetName'), volume: 0.85);
    } catch (_) {
      // Audio failed on this device, ignore safely without breaking any UI
    }
  }

  void playTap() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    _playSound('tap.wav');
  }

  void playCoin() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
    _playSound('coin.wav');
  }

  void playDraftPick() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
    _playSound('draft_pick.wav');
  }

  void playWhistle() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    _playSound('whistle.wav');
  }

  void playGoal() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    _playSound('goal.wav');
  }

  void playWin() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    _playSound('win_fanfare.wav');
  }

  void dispose() {
    try {
      _player?.dispose();
    } catch (_) {}
  }
}
