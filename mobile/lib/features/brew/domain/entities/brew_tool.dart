/// Entitas master alat seduh (Knowledge Base).
class BrewTool {
  final String toolId;
  final String toolName;
  final String? category;
  final String? imageAsset;
  final String? description;
  final bool isRequired;
  final String? notes;

  const BrewTool({
    required this.toolId,
    required this.toolName,
    this.category,
    this.imageAsset,
    this.description,
    this.isRequired = true,
    this.notes,
  });

  factory BrewTool.fromMap(Map<String, dynamic> map) {
    return BrewTool(
      toolId: map['tool_id'] as String,
      toolName: map['tool_name'] as String,
      category: map['category'] as String?,
      imageAsset: map['image_asset'] as String?,
      description: map['description'] as String?,
      isRequired: (map['is_required'] as int? ?? 1) == 1,
      notes: map['notes'] as String?,
    );
  }
}
