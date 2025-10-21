class AttachmentModel {
  final String id;
  final String fileName;
  final String filePath;
  final String mimeType;
  final int fileSize;
  final String fileHash;
  final DateTime uploadedAt;

  const AttachmentModel({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.fileSize,
    required this.fileHash,
    required this.uploadedAt,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      mimeType: json['mimeType'] as String,
      fileSize: json['fileSize'] as int,
      fileHash: json['fileHash'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'fileHash': fileHash,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  AttachmentModel copyWith({
    String? id,
    String? fileName,
    String? filePath,
    String? mimeType,
    int? fileSize,
    String? fileHash,
    DateTime? uploadedAt,
  }) {
    return AttachmentModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      fileHash: fileHash ?? this.fileHash,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
