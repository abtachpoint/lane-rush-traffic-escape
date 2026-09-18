import 'package:flame_audio/flame_audio.dart';

import 'game_store.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool _musicPlaying = false;

  Future<void> startMusic() async {
    if (!GameStore.instance.musicOn || _musicPlaying) return;
    try {
      await FlameAudio.bgm.play('music_loop.wav', volume: 0.16);
      _musicPlaying = true;
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
    _musicPlaying = false;
  }

  Future<void> refreshMusic() async {
    if (GameStore.instance.musicOn) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> play(String file, {double volume = 0.35}) async {
    if (!GameStore.instance.soundOn) return;
    try {
      await FlameAudio.play(file, volume: volume);
    } catch (_) {}
  }
}
