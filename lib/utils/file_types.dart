/// Shared file-extension helpers used wherever drawing/evidence attachments
/// are picked, queued offline, or uploaded (add/edit/view trial screens and
/// the sync engine all need the same mapping).
String extensionOf(String fileName) {
  return fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
}

String mimeTypeForExtension(String extension) {
  switch (extension.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'pdf':
      return 'application/pdf';
    case 'mp4':
      return 'video/mp4';
    case 'mov':
      return 'video/quicktime';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    default:
      return 'application/octet-stream';
  }
}

String fileEmojiForExtension(String? extension) {
  switch (extension?.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
    case 'png':
      return '🖼️';
    case 'pdf':
      return '📄';
    case 'mp4':
    case 'mov':
      return '🎥';
    case 'doc':
    case 'docx':
      return '📝';
    default:
      return '📎';
  }
}
