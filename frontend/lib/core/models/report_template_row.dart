/// Mirrors backend/routes/report-templates.routes.js — a personal saved
/// "which KPI/graph sections to show" view for the Reports screen.
class ReportTemplateRow {
  const ReportTemplateRow({required this.id, required this.name, required this.sections});

  final int id;
  final String name;
  final List<String> sections;

  factory ReportTemplateRow.fromJson(Map<String, dynamic> json) {
    return ReportTemplateRow(
      id: json['id'] as int,
      name: json['name'] as String,
      sections: (json['sections'] as List).cast<String>(),
    );
  }
}
