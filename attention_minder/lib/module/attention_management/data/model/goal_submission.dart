class GoalSubmission {
  const GoalSubmission({this.id, required this.goal, required this.rating});

  final int? id;
  final String goal;
  final int rating;

  GoalSubmission normalized() =>
      GoalSubmission(id: id, goal: goal.trim(), rating: rating.clamp(0, 5));

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) 'id': id,
    'goal': goal,
    'rating': rating,
  };
}
