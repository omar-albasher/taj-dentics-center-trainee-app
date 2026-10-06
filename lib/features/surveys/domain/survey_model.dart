class SurveyDispatch {
  final String dispatchId;
  final String templateId;
  final String surveyTitle;
  final List<dynamic> questions;
  final String status;
  final DateTime dispatchedAt;
  final bool isAnswered;

  const SurveyDispatch({
    required this.dispatchId,
    required this.templateId,
    required this.surveyTitle,
    required this.questions,
    required this.status,
    required this.dispatchedAt,
    required this.isAnswered,
  });

  factory SurveyDispatch.fromMap(Map<String, dynamic> map) {
    return SurveyDispatch(
      dispatchId: map['id'] ?? '',
      templateId: map['template_id'] ?? '',
      surveyTitle: map['survey_templates']?['title'] ?? '',
      questions: map['survey_templates']?['questions'] ?? [],
      status: map['status'] ?? 'pending',
      dispatchedAt: DateTime.parse(map['dispatched_at']),
      isAnswered: map['status'] == 'answered',
    );
  }
}
