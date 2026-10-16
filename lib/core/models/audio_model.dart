enum AudioSourceType { file, network }

class AudioModel {
  final String path;
  final AudioSourceType type;

  const AudioModel({required this.path, required this.type});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioModel &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          type == other.type;

  @override
  int get hashCode => path.hashCode ^ type.hashCode;
}
