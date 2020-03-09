/**
 * ExamScheduler.java
 * 
 * Main driver for the exam scheduler program.
 * 
 * @author Olga Koldachenko
 *
 */
public class ExamScheduler {

	private static String ARG_MSG = "Improper argument format!\n" + "The required arguments are:\n"
			+ "\t1. The relative path of the course info file.\n" + "\t2. The relative path of the room info file.\n"
			+ "\t3. The number of available time slots for exams, greater than zero.\n\n"
			+ "Example: courses.txt room.txt 25\n" + "Aborting.";

	public static void main(String[] args) {

		String course_filename = "courses.txt";

		try {
			course_filename = args[0];
		} catch (ArrayIndexOutOfBoundsException exc) {
			System.out.print(ARG_MSG);
			return;
		}

		String room_filename = "rooms.txt";

		try {
			room_filename = args[1];
		} catch (ArrayIndexOutOfBoundsException exc) {
			System.out.print(ARG_MSG);
			return;
		}

		int total_timeslots = 1;

		try {
			total_timeslots = Integer.parseInt(args[2]);

			if (total_timeslots < 1) {
				System.out.print(ARG_MSG);
				return;
			}
		} catch (ArrayIndexOutOfBoundsException exc) {
			System.out.print(ARG_MSG);
			return;
		}

		Schedule sched = new Schedule(total_timeslots);

		System.out.print("Attempting to read the course file... ");

		if (sched.loadCourses(course_filename)) {
			System.out.println("Success!");
		} else {
			System.out.println("Error! Aborting.");
			return;
		}

		System.out.print("Attempting to read the room file... ");

		if (sched.loadRooms(room_filename)) {
			System.out.println("Success!");
		} else {
			System.out.println("Error! Aborting.");
			return;
		}

		System.out.print("Calculating schedule... ");

		if (sched.calculateSchedule()) {
			System.out.println("Success!\n");
			System.out.print(sched);
		} else {
			System.out.println("Unable to create schedule within given parameters! Aborting.");
		}
	}
}
