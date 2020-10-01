-- EXAM SCHEDULER IN HASKELL
--
-- Olga Koldachenko      okold525@mtroyal.ca
-- COMP 3649             Assignment 3
-- Due: April 5 2020     Maryam Elahi
--
-- This program reads course data from CourseData.hs and room data from
-- RoomData.hs and creates a schedule based on the input. The "main"
-- function to call is sched CourseData RoomData Int, where the Int is
-- the number of Timeslots to create.

import CourseData
import RoomData
import Data.List
import Data.IntSet

------------------------------------------------------------------
-- DATA TYPES
-- Data types and related functions.

-- Course
-- Holds a course name and a collection of student IDs in a pair.
data Course = Course (String,IntSet)

instance Show Course where
    show (Course (name,set)) = "(" ++ name ++ "," ++ show (size set) ++ ")"
instance Eq Course where
    c1 == c2 = courseSize c1 == courseSize c2
instance Ord Course where
    c1 <= c2 = courseSize c1 <= courseSize c2

courseSize :: Course -> Int
courseSize (Course (_,xs)) = size xs

-- Room
-- Holds a room name and capacity in a pair.
data Room = Room (String,Int)
    deriving (Show)

instance Eq Room where
    (Room (_,r1)) == (Room (_,r2)) = r1 == r2
instance Ord Room where
    (Room (_,r1)) <= (Room (_,r2)) = r1 <= r2

subCapacity :: Room -> Int -> Room
subCapacity (Room (name,capacity)) x = Room (name,(capacity - x))

roomSize :: Room -> Int
roomSize (Room (_,capacity)) = capacity

-- Exam
-- Holds a course and a room name in a pair.
data Exam = Exam (Course,String)
    deriving (Eq)

instance Show Exam where
    show (Exam (Course (course_name,_),room_name)) = course_name ++ "\t" ++ room_name

createExam :: Course -> Room -> Exam
createExam course (Room (roomname,_)) = Exam (course,roomname)

-- Timeslot
-- Holds an exam list and available room list in a pair.
data Timeslot = Timeslot ([Exam],[Room])
    deriving (Eq)

instance Show Timeslot where
    show (Timeslot ([],_)) = ""
    show (Timeslot (e:es,r)) = 
        if (length es > 0)
            then show e ++ "\n" ++ show (Timeslot (es,r))
            else show e

timeslotIsEmpty :: Timeslot -> Bool
timeslotIsEmpty (Timeslot (es,_)) = es == []



------------------------------------------------------------------
-- "IO" FUNCTIONS
-- Handles the control, with "sched" being the "main"
-- Instead of true IO, reads from CourseData.hs and RoomData.hs

-- sched
-- Takes a list of CourseData, RoomData, and a number of timeslots and 
-- creates a schedule
sched :: CourseData -> RoomData -> Int -> IO()
sched cs rs x = 
    let ts = createTimeslotList (roomDataToRooms rs) x in
        let timeslotPair = insertCourseListIntoTimeslotList (courseDataToCourses cs) ts in
            if snd timeslotPair == True
                then printSchedule (fst timeslotPair)
                else putStr ("Cannot create a schedule!\n")

-- printSchedule
-- Prints the given list of Timeslots
printSchedule :: [Timeslot] -> IO()
printSchedule ts = putStr (scheduleToString ts)

-- scheduleToString and scheduleToString'
-- Converts a list of Timeslots into a String, starting the count at 1
scheduleToString :: [Timeslot] -> String
scheduleToString ts = scheduleToString' ts 1
scheduleToString' :: [Timeslot] -> Int -> String
scheduleToString' [] _ = ""
scheduleToString' (t:ts) x = 
    if (not (timeslotIsEmpty t))
    then "-TIMESLOT #" ++ show x ++ "-\n" ++ show t ++ "\n" ++ scheduleToString' ts (x+1)
    else ""

-- courseDataToCourses
-- Converts a list of CourseData to a list of Course data types
courseDataToCourses :: CourseData -> [Course]
courseDataToCourses cs = reverse (sort (courseDataToCourses' cs))
courseDataToCourses' :: CourseData -> [Course]
courseDataToCourses' [] = []
courseDataToCourses' (c:cs)
    | length (snd c) > 0 = Course (fst c,fromList (snd c)):courseDataToCourses cs
    | otherwise = courseDataToCourses cs

-- roomDataToRooms
-- Converts a list of RoomData to a list of Room data types
roomDataToRooms :: RoomData -> [Room]
roomDataToRooms rs = reverse (sort (roomDataToRooms' rs))
roomDataToRooms' :: RoomData -> [Room]
roomDataToRooms' [] = []
roomDataToRooms' (r:rs) = Room r:roomDataToRooms rs

-- createTimeslotList
-- Creates a list of timeslots with empty exam lists using the given list of
-- rooms as a template.
createTimeslotList :: [Room] -> Int -> [Timeslot]
createTimeslotList _ 0 = []
createTimeslotList rs x = Timeslot ([],rs):createTimeslotList rs (x - 1) 



------------------------------------------------------------------
-- SCHEDULE CALCULATION
-- The main processing for creating a schedule.

-- insertCourseListIntoTimeslotList
-- Takes a list of courses and a list of timeslots and creates a pair of
-- a list of timeslots and a boolean. The boolean is True if the operation
-- was successful, otherwise False.
insertCourseListIntoTimeslotList :: [Course] -> [Timeslot] -> ([Timeslot],Bool)
insertCourseListIntoTimeslotList [] ts = (ts,True)
insertCourseListIntoTimeslotList (c:cs) ts =
    if courseFitsInTimeslotList c ts
    then let newlist = insertCourseIntoTimeslotList c ts
            in insertCourseListIntoTimeslotList cs newlist
    else (ts,False)

-- insertCourseIntoTimeslotList
-- Inserts the given Course into the first Timeslot that it doesn't conflict
-- with from the given list and returns the modified Timeslot list.
-- Assumes courseFitsInTimeslotList was called first.
insertCourseIntoTimeslotList :: Course -> [Timeslot] -> [Timeslot]
insertCourseIntoTimeslotList _ [] = []
insertCourseIntoTimeslotList c (t:ts)
    | courseFitsInTimeslot c t = (insertCourseIntoTimeslot c t):ts
    | otherwise = t:(insertCourseIntoTimeslotList c ts)

-- insertCourseIntoTimeslot
-- Inserts the given Course into the given Timeslot and returns the modified
-- Timeslot. Assumes courseFitsInTimeslot was called first.
insertCourseIntoTimeslot :: Course ->  Timeslot -> Timeslot
insertCourseIntoTimeslot c (Timeslot (es,rs)) = 
    let examPair = insertCourseIntoRoomList c rs
        in Timeslot (fst examPair:es,snd examPair) 

-- insertCourseIntoRoomList
-- Inserts the given Course into the given Room list and returns a pair
-- of the resulting Exam and the modified Room list.
-- Assumes courseFitsInRoomList was called first.
insertCourseIntoRoomList :: Course -> [Room] -> (Exam,[Room])
insertCourseIntoRoomList c (r:rs)
    | courseFitsInRoom c r = 
        let roomPair = insertCourseIntoRoom c r 
            in  (fst roomPair, snd roomPair:rs)
    | otherwise = insertCourseIntoRoomList c rs

-- insertCourseIntoRoom
-- Inserts the given Course into the given Room and returns a pair of
-- the resulting Exam and the Room with the class size subtracted.
-- Assumes courseFitsInRoom was called first.
insertCourseIntoRoom :: Course -> Room -> (Exam,Room)
insertCourseIntoRoom c r = (createExam c r,subCapacity r (courseSize c))



------------------------------------------------------------------
-- COURSE FIT DETERMINATION
-- The functions that determine whether a Course will fit within the various
-- levels of the schedule.

courseFitsInTimeslotList :: Course -> [Timeslot] -> Bool
courseFitsInTimeslotList _ [] = False
courseFitsInTimeslotList c (t:ts) = 
    courseFitsInTimeslot c t || courseFitsInTimeslotList c ts

courseFitsInTimeslot :: Course -> Timeslot -> Bool
courseFitsInTimeslot c (Timeslot (es,rs)) = 
    (conflictsWithExamList c es == False) && (courseFitsInRoomList c rs)

courseFitsInRoomList :: Course -> [Room] -> Bool
courseFitsInRoomList _ [] = False
courseFitsInRoomList c (r:rs) = courseFitsInRoom c r || courseFitsInRoomList c rs

courseFitsInRoom :: Course -> Room -> Bool
courseFitsInRoom c r = (courseSize c) <= (roomSize r)



------------------------------------------------------------------
-- ADJACENCY DETERMINATION
-- The functions that determine whether one Course's student list overlaps
-- with another's.

conflictsWithExamList :: Course -> [Exam] -> Bool
conflictsWithExamList _ [] = False
conflictsWithExamList c (e:es) = conflictsWithExam c e || conflictsWithExamList c es

conflictsWithExam :: Course -> Exam -> Bool
conflictsWithExam c1 (Exam (c2,_)) = conflictsWithCourse c1 c2

conflictsWithCourse :: Course -> Course -> Bool
conflictsWithCourse (Course (_,l1)) (Course (_,l2)) = size (intersection l1 l2) > 0
