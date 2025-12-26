/// Example demonstrating the sorting behavior
/// This file shows how the sorting works - can be deleted after verification

import 'sorting_utils.dart';

void demonstrateSorting() {
  // Test class batch sorting (should be 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
  final classBatches = ['10', '2', '1', '5', '3', '8', '6', '9', '4', '7'];
  final sortedClasses = SortingUtils.sortClassBatches(classBatches);
  print('Class batches sorted: $sortedClasses');
  // Expected: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  
  // Test roll number sorting (should be 1, 2, 3, 4, 5, 10, 11, 12)
  final rollNumbers = ['12', '2', '1', '11', '3', '10', '4', '5'];
  final sortedRolls = SortingUtils.sortRollNumbers(rollNumbers);
  print('Roll numbers sorted: $sortedRolls');
  // Expected: [1, 2, 3, 4, 5, 10, 11, 12]
  
  // Test name sorting (should be A, B, C... Z)
  final names = ['Zara', 'Alice', 'Bob', 'Charlie', 'David'];
  final sortedNames = SortingUtils.sortNames(names);
  print('Names sorted: $sortedNames');
  // Expected: [Alice, Bob, Charlie, David, Zara]
  
  // Test subject sorting (should be A, B, C... Z)
  final subjects = ['Science', 'Mathematics', 'English', 'Hindi'];
  final sortedSubjects = SortingUtils.sortSubjects(subjects);
  print('Subjects sorted: $sortedSubjects');
  // Expected: [English, Hindi, Mathematics, Science]
  
  // Test topics sorting (should be A, B, C... Z)
  final topics = ['Zoology', 'Algebra', 'Biology', 'Chemistry'];
  final sortedTopics = SortingUtils.sortTopics(topics);
  print('Topics sorted: $sortedTopics');
  // Expected: [Algebra, Biology, Chemistry, Zoology]
}

/*
Expected Output:
Class batches sorted: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
Roll numbers sorted: [1, 2, 3, 4, 5, 10, 11, 12]
Names sorted: [alice, bob, charlie, david, zara]
Subjects sorted: [english, hindi, mathematics, science]
Topics sorted: [algebra, biology, chemistry, zoology]

STUDENT SORTING:
Students are now sorted by NAME FIRST (A to Z), then by class, then by roll number.
Example:
- Alice (Class 5, Roll 10)
- Alice (Class 6, Roll 5)  
- Bob (Class 3, Roll 1)
- Charlie (Class 3, Roll 2)
- David (Class 1, Roll 15)
- Zara (Class 2, Roll 8)

This demonstrates:
1. Numbers: 1 at top, bigger numbers below (1, 2, 3, 4, 5...)
2. Alphabetical: A at top, Z at end (A, B, C... Z)
3. Students: NAME FIRST (A-Z), then class (1-10), then roll (1-100)
*/