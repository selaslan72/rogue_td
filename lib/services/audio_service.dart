import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SfxCue {
  place,
  upgrade,
  sell,
  waveStart,
  waveClear,
  enemyDie,
  leak,
  victory,
  defeat,
  shotArrow,
  shotCannon,
  shotFire,
  shotTesla,
  shotBarracks,
}

class AudioService {
  AudioService._();
  static final instance = AudioService._();

  static const _enabledKey = 'audio_sfx_enabled_v1';

  final ValueNotifier<bool> enabledNotifier = ValueNotifier(true);
  final Map<SfxCue, int> _lastPlayedAt = {};
  bool _loaded = false;

  bool get enabled => enabledNotifier.value;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    enabledNotifier.value = prefs.getBool(_enabledKey) ?? true;
    unawaited(_preload());
    _loaded = true;
  }

  Future<void> setEnabled(bool value) async {
    enabledNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<void> toggleEnabled() => setEnabled(!enabled);

  void play(SfxCue cue) {
    if (!enabled) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cooldown = _cooldowns[cue] ?? 0;
    final last = _lastPlayedAt[cue] ?? 0;
    if (now - last < cooldown) return;
    _lastPlayedAt[cue] = now;
    unawaited(_play(cue));
  }

  Future<void> _preload() async {
    try {
      await FlameAudio.audioCache.loadAll(_paths.values.toSet().toList());
    } catch (_) {
      // Audio is cosmetic; keep gameplay alive if the platform rejects preload.
    }
  }

  Future<void> _play(SfxCue cue) async {
    try {
      await FlameAudio.play(_paths[cue]!, volume: _volumes[cue] ?? 0.45);
    } catch (_) {
      // Missing/autoplay-blocked sounds should never interrupt a run.
    }
  }

  static const Map<SfxCue, String> _paths = {
    SfxCue.place: 'sfx/place.wav',
    SfxCue.upgrade: 'sfx/upgrade.wav',
    SfxCue.sell: 'sfx/sell.wav',
    SfxCue.waveStart: 'sfx/wave_start.wav',
    SfxCue.waveClear: 'sfx/wave_clear.wav',
    SfxCue.enemyDie: 'sfx/enemy_die.wav',
    SfxCue.leak: 'sfx/leak.wav',
    SfxCue.victory: 'sfx/victory.wav',
    SfxCue.defeat: 'sfx/defeat.wav',
    SfxCue.shotArrow: 'sfx/shot_arrow.wav',
    SfxCue.shotCannon: 'sfx/shot_cannon.wav',
    SfxCue.shotFire: 'sfx/shot_fire.wav',
    SfxCue.shotTesla: 'sfx/shot_tesla.wav',
    SfxCue.shotBarracks: 'sfx/shot_barracks.wav',
  };

  static const Map<SfxCue, double> _volumes = {
    SfxCue.enemyDie: 0.22,
    SfxCue.shotArrow: 0.18,
    SfxCue.shotCannon: 0.22,
    SfxCue.shotFire: 0.16,
    SfxCue.shotTesla: 0.18,
    SfxCue.shotBarracks: 0.14,
    SfxCue.waveStart: 0.34,
    SfxCue.waveClear: 0.32,
    SfxCue.victory: 0.42,
    SfxCue.defeat: 0.36,
  };

  static const Map<SfxCue, int> _cooldowns = {
    SfxCue.enemyDie: 60,
    SfxCue.shotArrow: 55,
    SfxCue.shotCannon: 90,
    SfxCue.shotFire: 75,
    SfxCue.shotTesla: 70,
    SfxCue.shotBarracks: 95,
    SfxCue.leak: 120,
  };
}
