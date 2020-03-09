/**
 * Timeslot.java
 * 
 * A fresh timeslot holds a list of fully available rooms, then is filled out by the
 * Schedule object.
 * 
 */
import java.util.ArrayList;
import java.util.HashMap;

public class Timeslot {
	private int[] available_seats;
	private ArrayList<Room> room_list;
	private HashMap<Course, Room> courses_written;

	/**
	 * Creates a timeslot with the given room list. The available seats are stored
	 * as a 1D array of integers, with the index of the room corresponding to the
	 * index in the room_list.
	 */
	public Timeslot(ArrayList<Room> room_list) {
		this.room_list = room_list;
		courses_written = new HashMap<>();

		available_seats = new int[room_list.size()];

		for (int i = 0; i < room_list.size(); i++) {
			available_seats[i] = room_list.get(i).getCapacity();
		}
	}

	/**
	 * Attempts to add the given course to the timeslot. Returns false if failed.
	 * Iterates through all the available seats and fits the course into the first
	 * room that will fit it.
	 */
	public boolean addCourse(Course course) {
		if (hasConflictingCourse(course)) {
			return false;
		}

		for (int i = 0; i < available_seats.length; i++) {
			if (available_seats[i] >= course.size()) {
				courses_written.put(course, room_list.get(i));
				available_seats[i] -= course.size();
				return true;
			}
		}
		return false;
	}

	/**
	 * Returns true if the given course shares a student with one of the courses in
	 * this timeslot.
	 */
	public boolean hasConflictingCourse(Course a_course) {
		for (Course course : courses_written.keySet()) {
			if (course.sharesStudentWith(a_course)) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Removes the room from the timeslot and adds the taken seats back to the room.
	 */
	public boolean removeCourse(Course a_course) {
		if (courses_written.containsKey(a_course)) {
			Room room = courses_written.get(a_course);
			int index = room_list.indexOf(room);
			available_seats[index] += room.getCapacity();
			courses_written.remove(a_course);
			return true;
		}

		return false;
	}

	public String toString() {
		String str = "";

		for (Course course : courses_written.keySet()) {
			str += course;
			if (course.getName().length() >= 8) {
				str += "\t";
			} else {
				str += "\t\t";
			}

			str += courses_written.get(course).getName() + '\n';
		}
		return str;
	}
}
