/**
 * Course.java
 * 
 * Holds information about a course.
 * - A name
 * - A list of students in the course
 * - A list of courses adjacent to this course (share students) as generated by
 * 	 Schedule.java.
 * 
 */
import java.util.ArrayList;
import java.util.HashSet;

public class Course implements Comparable<Course>{
	private String name;
	private HashSet<Integer> student_set;
	private ArrayList<Course> shared_list;

	/**
	 * Creates a course with the given name and initializes the student set and
	 * adjacent courses list to empty.
	 */
	public Course(String name) {
		this.name = name;
		student_set = new HashSet<>();
		shared_list = new ArrayList<>();
	}

	/**
	 * Adds a student to the course by student ID.
	 */
	public boolean add(int student_id) {
		return student_set.add(student_id);
	}

	/**
	 * Returns true if this course shares a student with the given course.
	 */
	public boolean sharesStudentWith(Course other) {
		if (other == this) {
			return false;
		}

		for (int student : student_set) {
			if (other.student_set.contains(student)) {
				return true;
			}
		}

		return false;
	}

	/**
	 * Adds the adjacent course to the list, ignoring duplicates.
	 */
	public void addToSharedList(Course other) {
		if (!shared_list.contains(other)) {
			shared_list.add(other);
		}
	}

	public String getName() {
		return name;
	}

	public int size() {
		return student_set.size();
	}

	public String toString() {
		return name;
	}
	
	@Override
	public int compareTo(Course other) {
		// TODO Auto-generated method stub
		return this.student_set.size() - other.student_set.size();
	}
}