extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
  
  String truncate(int maxLength) {
    if (this.length <= maxLength) return this;
    return "${this.substring(0, maxLength)}...";
  }
} 