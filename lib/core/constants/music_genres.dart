import 'package:flutter/material.dart';

/// 🎵 MUSIC GENRES
///
/// Shared constants for music genres used across the app

class MusicGenres {
  MusicGenres._();

  static const List<String> genres = [
    'Rock',
    'Jazz',
    'Pop',
    'Hip-Hop',
    'R&B',
    'Country',
    'Electronic',
    'Classical',
    'Folk',
    'Indie',
    'Metal',
    'Blues',
    'Reggae',
    'Soul',
    'Funk',
    'Latin',
    'World',
    'Alternative',
    'Punk',
    'Gospel',
    'EDM',
    'Acoustic',
    'Singer-Songwriter',
    'Cover Band',
    'DJ',
  ];

  /// Get genre icon
  static IconData getIcon(String genre) {
    switch (genre.toLowerCase()) {
      case 'rock':
      case 'metal':
      case 'punk':
        return Icons.music_note;
      case 'jazz':
      case 'blues':
        return Icons.piano;
      case 'electronic':
      case 'edm':
      case 'dj':
        return Icons.headphones;
      case 'classical':
        return Icons.music_note;
      case 'hip-hop':
      case 'r&b':
        return Icons.mic;
      default:
        return Icons.music_note;
    }
  }
}
