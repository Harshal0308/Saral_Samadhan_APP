
class Student {
  final int id;
  final String name;
  final String rollNo;
  final String classBatch;
  bool isPresent;
  final List<double>? embeddings;

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.classBatch,
    this.isPresent = false,
    this.embeddings,
  });
}
