import '../data/models/course_config.dart';
import '../data/models/fleet_broadcast.dart';
import '../data/models/mark.dart';
import '../data/models/mark_distance.dart';

abstract class CoursesRepository {
  const CoursesRepository();

  // Courses
  Stream<List<CourseConfig>> watchAllCourses();
  Future<CourseConfig?> getCourse(String id);
  Future<void> saveCourse(CourseConfig course);
  Future<void> deleteCourse(String id);

  // Marks
  Future<List<Mark>> getMarks();
  Stream<List<Mark>> watchMarks();
  Future<void> saveMark(Mark mark);
  Future<void> deleteMark(String id);
  Future<List<MarkDistance>> getMarkDistances();

  // Course selection
  Future<void> selectCourseForEvent(String eventId, String courseId);
  Stream<String?> watchSelectedCourse(String eventId);

  // Fleet broadcasts
  Future<void> sendBroadcast(FleetBroadcast broadcast);
  Stream<List<FleetBroadcast>> watchBroadcasts({String? eventId});

}
