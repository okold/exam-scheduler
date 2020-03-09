/**
 * Room.java
 *
 * Holds room information (a name and seating capacity).
 * 
 */
public class Room implements Comparable<Room> {
	private String name;
	private int capacity;

	/**
	 * Creates a Room with the given name and capacity.
	 */
	public Room(String name, int capacity) {
		this.name = name;
		this.capacity = capacity;
	}

	public String getName() {
		return name;
	}

	public int getCapacity() {
		return capacity;
	}

	public String toString() {
		return name + ": " + capacity;
	}

	@Override
	public int compareTo(Room other) {
		// TODO Auto-generated method stub
		return this.capacity - other.capacity;
	}
}
