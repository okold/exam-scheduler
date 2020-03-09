/**
 * Schedule.java
 * 
 * The schedule object reads a course and a room file, then attempts to generate 
 * a schedule by assigning all available courses to the available timeslots.
 *  
 * The solution is not perfect - it does not backtrack while assigning rooms
 * within timeslots, as the program determines whether a course can fit in a
 * timeslot by checking if there exists a room that the course can fit inside.
 * There may be cases where there is a low number of timeslots where the program
 * is unable to create a schedule but it is actually possible.
 *
 */
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Scanner;

public class Schedule {
	private ArrayList<Course> course_list;
	private ArrayList<Room> room_list;
	private ArrayList<Timeslot> timeslot_list;
	private int max_slots;

	public Schedule(int max_slots) {
		this.max_slots = max_slots;
		course_list = new ArrayList<>();
		room_list = new ArrayList<>();
		timeslot_list = new ArrayList<>();
	}

	/**
	 * Creates a list of courses based on a given file path, then calculates which
	 * courses are adjacent to each other, determined by shared students. Sorts the
	 * courses by class size afterwards, in non-ascending order. Returns false upon
	 * hitting an IO or formatting error.
	 * 
	 * @param course_filename - The relative path of the course file.
	 * @return boolean - A success flag. False upon hitting an error.
	 */
	public boolean loadCourses(String course_filename) {
		try (Scanner file = new Scanner(new File(course_filename))) {
			String current_string = "";
			Course current_course;
			int current_int;

			if (file.hasNext()) // creates first course
			{
				current_string = file.next();

				if (!isValidCourseName(current_string)) {
					file.close();
					return false;
				}

				current_course = new Course(current_string);
				course_list.add(current_course);
			} else {
				file.close();
				return false; // empty file
			}

			while (file.hasNext()) {
				current_string = file.next();

				try // attempts to add a new student to the current course
				{
					current_int = Integer.parseInt(current_string);

					if ((current_int < 0) || !current_course.add(current_int)) {
						file.close();
						return false; // student ID cannot be negative / duplicate
					}

				} catch (NumberFormatException exc) // failure to parse integer, create new course
				{
					if (!isValidCourseName(current_string) || courseExists(current_string)) {
						file.close();
						return false; // improper course name format
					}

					current_course = new Course(current_string);
					course_list.add(current_course);
				}
			}

			file.close();
		} catch (IOException exc) {
			return false;
		}

		generateAdjList();
		Collections.sort(course_list, Collections.reverseOrder());

		return true;
	}

	/**
	 * Creates a list of rooms read from a given file path, then sorts the rooms
	 * based on class size. Returns false if it comes across an IO or formatting
	 * error.
	 * 
	 * @param room_filename - The relative path of the room file.
	 * @return boolean - A success flag. False upon hitting an error.
	 */
	public boolean loadRooms(String room_filename) {
		try (Scanner file = new Scanner(new File(room_filename))) {
			String room_name = "";
			int room_capacity = 0;

			if (!file.hasNext()) {
				file.close();
				return false; // empty file
			}

			while (file.hasNext()) // get next room name
			{
				room_name = file.next();

				if (file.hasNext()) // get next room size
				{
					try {
						room_capacity = Integer.parseInt(file.next());

						if (room_capacity < 0) {
							file.close();
							return false; // bad capacity
						}
					} catch (NumberFormatException exc) {
						file.close();
						return false; // parse fail
					}

				} else {
					file.close();
					return false; // mismatch
				}

				if (!roomExists(room_name)) {
					room_list.add(new Room(room_name, room_capacity));
				} else {
					file.close();
					return false; // duplicate room
				}
			}

			file.close();
		} catch (IOException exc) {
			return false;
		}

		Collections.sort(room_list);

		return true;
	}

	/**
	 * Adds a list of adjacent Courses to each Course, where a course is adjacent if
	 * they share at least one student.
	 */
	private void generateAdjList() {
		for (Course course : course_list) {
			for (Course course2 : course_list) {
				if ((course != course2) && (course.sharesStudentWith(course2))) {
					course.addToSharedList(course2);
					course2.addToSharedList(course);
				}

			}
		}
	}

	/**
	 * Attempts to calculate a schedule by calling insertCourseIntoTimeslot using
	 * the first course and first timeslot.
	 * 
	 * Should only ever be run once. The rooms and courses must be loaded first.
	 * 
	 * Returns false upon failing.
	 * 
	 * @return boolean - A success flag. False upon hitting an error.
	 */
	public boolean calculateSchedule() {

		if (insertIntoSchedule(0, 0)) {
			return true;
		} else {
			return false;
		}
	}

	/**
	 * Recursive portion of the schedule calculation.
	 * 
	 * Traverses the course and timeslot lists, and attempts to add each course into
	 * each timeslot. If any part of the current attempt's branch fails, the
	 * algorithm backtracks and attempts the next timeslot starting at that point.
	 * 
	 * @param course_index   the index of the course in course_list
	 * @param timeslot_index the index of the timeslot in timeslot_list
	 * @param current        the current version of the schedule
	 * @return a complete schedule, or null upon failure
	 */
	private boolean insertIntoSchedule(int course_index, int timeslot_index) {
		if (course_index >= course_list.size()) {
			return true; // fit all courses into timeslots
		}

		if (timeslot_index >= max_slots) {
			return false; // exceeded maximum number of timeslots
		}

		Timeslot slot = null;

		if (timeslot_index >= timeslot_list.size()) {
			slot = new Timeslot(room_list);
			timeslot_list.add(slot);
		} else {
			slot = timeslot_list.get(timeslot_index);
		}

		Course course = course_list.get(course_index);

		if (slot.addCourse(course)) {
			if (insertIntoSchedule(course_index + 1, 0)) {
				return true;
			} else {
				slot.removeCourse(course);
				return insertIntoSchedule(course_index, timeslot_index + 1);
			}
		} else {
			return insertIntoSchedule(course_index, timeslot_index + 1);
		}
	}

	/**
	 * Checks that the first character of the String is a letter.
	 * 
	 * @param course_name - The String to validate.
	 * @return boolean - success flag - True if valid.
	 */
	private static boolean isValidCourseName(String course_name) {
		if (course_name.toUpperCase().charAt(0) < 'A' || course_name.toUpperCase().charAt(0) > 'Z') {
			return false;
		}

		return true;
	}

	/**
	 * Returns true if a course exists with the given name.
	 */
	private boolean courseExists(String name) {
		for (Course course : course_list) {
			if (course.getName().equalsIgnoreCase(name)) {
				return true;
			}
		}

		return false;
	}

	/**
	 * Returns true if a room exists with the given name.
	 */
	private boolean roomExists(String name) {
		for (Room room : room_list) {
			if (room.getName().equalsIgnoreCase(name)) {
				return true;
			}
		}

		return false;
	}

	public String toString() {
		String str = "";

		for (int i = 0; i < timeslot_list.size(); i++) {
			str += "-TIMESLOT #" + (i + 1) + "-\n";
			str += timeslot_list.get(i) + "\n";
		}
		return str;
	}
}
