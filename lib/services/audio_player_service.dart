import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/podcast_item.dart';

enum AudioPlayState { stopped, playing, paused }

class AudioPlayerService with ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();

  AudioPlayState _state = AudioPlayState.stopped;
  AudioPlayState get state => _state;

  PodcastItem? _currentPodcast;
  PodcastItem? get currentPodcast => _currentPodcast;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  Timer? _sleepTimer;
  int _sleepMinutesRemaining = 0;
  int get sleepMinutesRemaining => _sleepMinutesRemaining;

  void _init() {
    _player.onPlayerStateChanged.listen((s) {
      if (s == PlayerState.playing) {
        _state = AudioPlayState.playing;
      } else if (s == PlayerState.paused) {
        _state = AudioPlayState.paused;
      } else {
        _state = AudioPlayState.stopped;
      }
      notifyListeners();
    });

    _player.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });

    _player.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });
  }

  Future<void> playPodcast(PodcastItem podcast) async {
    _currentPodcast = podcast;
    _state = AudioPlayState.playing;
    notifyListeners();

    try {
      await _player.stop();
      await _player.play(UrlSource(podcast.audioUrl));
    } catch (e) {
      if (podcast.fallbackAudioUrl != null && podcast.fallbackAudioUrl!.isNotEmpty) {
        try {
          await _player.play(UrlSource(podcast.fallbackAudioUrl!));
          return;
        } catch (_) {}
      }
      // ignore: avoid_print
      print('Error playing audio: $e');
      _state = AudioPlayState.stopped;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _state = AudioPlayState.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    await _player.resume();
    _state = AudioPlayState.playing;
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _state = AudioPlayState.stopped;
    _position = Duration.zero;
    cancelSleepTimer();
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void setSleepTimer(int minutes) {
    cancelSleepTimer();
    if (minutes <= 0) return;

    _sleepMinutesRemaining = minutes;
    notifyListeners();

    _sleepTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _sleepMinutesRemaining--;
      notifyListeners();
      if (_sleepMinutesRemaining <= 0) {
        stop();
        cancelSleepTimer();
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepMinutesRemaining = 0;
    notifyListeners();
  }
}
