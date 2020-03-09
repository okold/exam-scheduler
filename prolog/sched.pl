% EXAM SCHEDULER IN PROLOG
%
% Olga Koldachenko      okold525@mtroyal.ca
% COMP 3649             Assignment 2
% Due: March 11 2020    Maryam Elahi
%
% This program reads two files: one with course information and the other
% with room information, and combined with a given number of timeslots,
% generates an exam schedule.
%
% FILE FORMATTING INFORMATION:
%   -   The course and room names are case insensitive. To handle this,
%       the program forces all names to upper case.
%   -   The course name must start with a letter.
%   -   The room name can be made up of any non-whitespace characters.
%   -   The student IDs and room capacities must be >= 0
%   -   Any whitespace delimits information in the files.
%
% STRUCTURES USED:
%   -   course(String Name, [Int] StudentIDList)
%   -   room(String Name, Int Capacity)
%   -   exam(Course Course, String RoomName)
%   -   timeslot([Exam] ExamList, [Room] AvailableRoomList)

%:- debug.

:- op(650, xfx, conflictsWith).
:- op(650, xfx, hasClassSize). 
:- op(650, xfx, alreadyExistsIn). 
:- op(650, xf, isEmpty).

%%%%%%%%%%%%%%%% UTILITIES %%%

% Various helper relations copied from IOExamples - ReadIDS.pl
if(Test,Then,Else) :-
    Test,!,Then
    ;
    Else.
if(Test,Then) :- if(Test,Then,true).

isSpace(Ch) :- code_type(Ch,space).
isNotSpace(Ch) :- not(isSpace(Ch)).


%%%%%%%%%%%%%%%% SCHEDULE LOGIC %%%

% sched/3
% Prints a schedule created using the given filenames and timeslots.
sched(CourseFile,RoomFile,NumTimeslots) :-
    if(NumTimeslots =< 0,
        (
            write("Invalid number of timeslots! Aborting."),fail
        ),
        (
            readFileToCourseData(CourseFile,CourseList),
            readFileToRoomData(RoomFile,RoomList),
            (
                createTimeslotList(RoomList,NumTimeslots,TimeslotList),
                (
                    generateSchedule(CourseList,TimeslotList,Schedule),
                    removeEmptyTimeslots(Schedule,CleanSchedule),
                    printSchedule(CleanSchedule,1)
                );
                write("Unable to create a schedule within the given parameters! Aborting."),fail
            )
        )
    ).

% createTimeslotList/3
% The first argument is the room list to insert into each timeslot.
% The second argument is the number of timeslots to generate.
% The third argument is the list of identical timeslots.
%
% Note: No error checking is done on the base case.
% Calling this with NumTimeSlots <= 0 will cause infinite recursion.
% For the purposes of this assignment, error checking on this value is
% done in sched/3.
createTimeslotList(RoomList,NumTimeslots,TimeslotList) :-
    Timeslot = timeslot([],RoomList),
    if((NumTimeslots = 1),
        (
            TimeslotList = [Timeslot]
        ),
        (
            LessTimeslots is NumTimeslots - 1,
            createTimeslotList(RoomList,LessTimeslots,OtherTimeslots),
            TimeslotList = [Timeslot|OtherTimeslots]
        )
    ).

% generateSchedule/3
% AKA "fitCourseListIntoTimeslotList" but that's a bit wordy...
% The first argument is the list of courses left to process.
% The second argument is the list of timeslots to fit the courses into.
% The third argument is the resulting schedule.
generateSchedule([],TimeslotList,TimeslotList).
generateSchedule([Head|Tail],TimeslotList,Schedule) :-
    fitCourseIntoTimeslotList(Head,TimeslotList,TimeslotListWithHead),
    generateSchedule(Tail,TimeslotListWithHead,Schedule).

% removeEmptyTimeslots/2
% The first argument is a list of timeslots (a schedule).
% The second argument is the list with all empty timeslots removed.
removeEmptyTimeslots([],[]).
removeEmptyTimeslots([Head|Tail],CleanSchedule) :-
    removeEmptyTimeslots(Tail,CleanTail),
    (
        if((Head isEmpty),
            (
                CleanSchedule = CleanTail
            ),
            (
                CleanSchedule = [Head|CleanTail]
            )
        )
    ).

% fitCourseIntoTimeslotList/3
% The first argument is the course to attempt to fit.
% The second argument is the list of timeslots to attempt to fit into.
% The third argument is the list of timeslots after the course's insertion.
fitCourseIntoTimeslotList(Course,[Head|Tail],NextTimeslotList) :-
    (
        fitCourseIntoTimeslot(Course,Head,NextHead),
        NextTimeslotList = [NextHead|Tail]
    );
    (
        fitCourseIntoTimeslotList(Course,Tail,SmallerTimeslotList),
        NextTimeslotList = [Head|SmallerTimeslotList]
    ).

% fitCourseIntoTimeslot/3
% The first argument is the course to attempt to fit.
% The second argument is the timeslot to attempt to fit the course into.
% The third argument is the timeslot after the room has been inserted.
fitCourseIntoTimeslot(Course,timeslot(ExamList,AvailableRooms),NextTimeslot) :-
    not(Course conflictsWith ExamList),
    fitCourseIntoRoomList(Course,AvailableRooms,Exam,NextRoomList),
    NextExamList = [Exam|ExamList],
    NextTimeslot = timeslot(NextExamList,NextRoomList).

% fitCourseIntoRoomList/4.
% The first argument is the course to find a room for.
% The second argument is the list of rooms to fit the course into.
% The third argument is the resulting exam.
% The fourth argument is the remaining room list.
fitCourseIntoRoomList(Course,[Head|Tail],Exam,NextRoomList) :-
    (
        fitCourseIntoRoom(Course,Head,Exam,NextHead),
        NextRoomList = [NextHead|Tail]
    );
    (
        fitCourseIntoRoomList(Course,Tail,Exam,SmallerRoomList),
        NextRoomList = [Head|SmallerRoomList]
    ).

% fitCourseIntoRoom/4
% The first argument is the course to attempt to fit.
% The second argument is the room to attempt to fit the course into.
% The third argument is the resulting exam.
% The fourth argument is the room with the course's capacity subtracted.
fitCourseIntoRoom(Course,room(RoomName,Capacity),Exam,RoomAfter) :-
    Course hasClassSize ClassSize,
    NewCapacity is Capacity - ClassSize,
    NewCapacity >= 0,
    Exam = exam(Course,RoomName),
    RoomAfter = room(RoomName,NewCapacity).

% conflictsWith/2
% True if the first argument (a given course) conflicts with the the 
% second argument, which can be another course, an exam, a timeslot, or 
% a list of any of those structures.
%
% intersection/3 documentation: 
% https://www.swi-prolog.org/pldoc/man?predicate=intersection%2F3
conflictsWith(Course1,Course2) :- Course1 = Course2,!.

conflictsWith(course(_,SL1),course(_,SL2)) :-
    intersection(SL1, SL2, Intersection),
    not(Intersection = []),!.

conflictsWith(Course1,exam(Course2,_)) :-
    Course1 conflictsWith Course2,!.

conflictsWith(Course, [Head|Tail]) :-
    Course conflictsWith Head;
    Course conflictsWith Tail,!.

conflictsWith(Course,timeslot(ExamList,_)) :-
    Course conflictsWith ExamList,!.

% hasClassSize/2
% The first argument is a course.
% The second argument is the class size of the course.
hasClassSize(course(_,StudentIDList),ClassSize) :-
    length(StudentIDList,ClassSize).

% isEmpty/1
% True if the given timeslot is empty.
isEmpty(timeslot(ExamList,_)) :-
    length(ExamList,NumExams),
    NumExams = 0.

% printSchedule/1
% Prints the given schedule.
printSchedule([],_) :- !.
printSchedule([Head|Tail], TimeslotNumber) :-
    write("-TIMESLOT #"),write(TimeslotNumber),write("-"),nl,
    printTimeslot(Head),nl,!,
    NextTimeslotNumber is TimeslotNumber + 1,
    printSchedule(Tail,NextTimeslotNumber),!.

% printTimeslot/1
% Prints the given timeslot.
printTimeslot(timeslot([],_)).
printTimeslot(timeslot([Head|Tail],_)) :-
    printExam(Head),nl,!,
    printTimeslot(timeslot(Tail,_)).

% printExam/1
% Prints the given exam.
printExam(exam(course(CourseName,_),RoomName)) :-
    write(CourseName),write('\t'),write(RoomName).


%%%%%%%%%%%%%%%% I/O LOGIC %%%

% readFileToCourseData/2
% Receives the name of a file and converts it to a list of courses.
% Format:   course(CourseName,IDList)
readFileToCourseData(Filename, CourseData) :-
    catch(read_file_to_codes(Filename,Codes,[]),_,
        (
            write("Unable to read course data file! Aborting."),nl,fail
        )
    ),!,
    getCourseData(Codes,CourseData).

% getCourseData/2
% The first argument represents the list of char codes to parse.
% The second argument is a list of courses.
% Format:   course(CourseName,IDList)
getCourseData([],[]).
getCourseData(Codes,CourseData) :-
    removeLeadingWhitespace(Codes, NoWhiteSpace),
    selectNextWord(CourseNameCodes,NoWhiteSpace,IDString),
    CourseNameCodes = [H|_],
    char_type(H,alpha),
    string_codes(CourseName, CourseNameCodes),
    string_upper(CourseName,CourseNameUpper),
    getNextIntegerList(IDString,IDList,Rest),
    getCourseData(Rest,RestCourseData),!,
    if((CourseNameUpper alreadyExistsIn RestCourseData),
        (
            write("Duplicate course in file! Aborting."),fail
        )
    ),
    CourseData = [course(CourseNameUpper,IDList)|RestCourseData].

% readFileToRoomData/2
% Receives the name of a file and converts it to a list of rooms.
% Format:   room(RoomName,Capacity)
readFileToRoomData(Filename, RoomData) :-
    catch(read_file_to_codes(Filename,Codes,[]),_,
        (
            write("Unable to read room data file! Aborting."),nl,fail
        )
    ),!,
    getRoomData(Codes,RoomData).

% getRoomData/2
% The first argument represents the list of char codes to parse.
% The second argument is a list of rooms.
% Format:   room(RoomName,Capacity)
getRoomData([],[]).
getRoomData(Codes,RoomData) :-
    removeLeadingWhitespace(Codes, NoWhiteSpace),
    selectNextWord(RoomNameCodes,NoWhiteSpace,Codes2),
    string_codes(RoomName, RoomNameCodes),
    string_upper(RoomName,RoomNameUpper),
    removeLeadingWhitespace(Codes2, NoWhiteSpace2),
    selectNextWord(CapacityCodes,NoWhiteSpace2,Rest),
    string_codes(CapacityString,CapacityCodes),
    atom_number(CapacityString,Capacity),
    if((Capacity < 0),
        (
            write("A room has capacity < 0! Aborting."),fail
        )
    ),
    getRoomData(Rest,RestRoomData),!,
    if((RoomNameUpper alreadyExistsIn RestRoomData),
        (
            write("Duplicate room in file! Aborting."),fail
        )
    ),
    RoomData = [room(RoomNameUpper,Capacity)|RestRoomData].

% removeLeadingWhitespace/2
% The first argument represents a list of char codes.
% The second argument is the first list with whitespace removed from
% the beginning.
%
% Modified version of removeSpace/2 provided in IOExamples - ReadIDS.pl
removeLeadingWhitespace([],[]).
removeLeadingWhitespace([H|T], Rest) :-
    if(isSpace(H),
        (
            removeLeadingWhitespace(T, Rest)
        ),
        (
            Rest = [H|T]
        )
    ).

% selectNextWord/3
% The first argument represents the next word in the list provided by the
% second argument, in the format of a list of char codes. Stops when
% encountering whitespace.
% The third argument is the list of char codes following the word.
%
% Modified version of splitInteger/3 provided in IOExamples - ReadIDS.pl
selectNextWord([],[],[]).
selectNextWord(Word,[H|T],Rest) :-
    if(isNotSpace(H),
        (
            selectNextWord(Word2,T,Rest),
            Word=[H|Word2]
        ),
        (
            Word=[],Rest=[H|T]
        )
    ).

% getNextIntegerList/3
% The first argument represents the list of char codes to parse.
% The second argument is the list of consecutive integers at the start of 
% the char code list. Stops parsing when a non-digit character is reached.
% The third argument is the list of char codes following the integers.
%
% Note: May be able to condense string_codes and atom_number.
getNextIntegerList([],[],[]).
getNextIntegerList(Codes, IntegerList, Rest) :-
    removeLeadingWhitespace(Codes, NoWhiteSpace),
    selectNextWord(Word,NoWhiteSpace,Next),
    string_codes(String,Word),
    if(atom_number(String, Number),
        (
            if((Number < 0),
                (
                    write("A student ID is < 0, aborting!"),fail
                )
            ),
            getNextIntegerList(Next,NextIntegerList, Rest),
            (
                (
                    member(Number,NextIntegerList),
                    write("Duplicate student in course! Aborting."),!,
                    fail
                );
                IntegerList = [Number|NextIntegerList]
            )
        ),
        (
            (IntegerList = []),(Rest = NoWhiteSpace)
        )
    ).

% alreadyExistsIn/2
% True if the first argument (a course name) already exists within the
% second argument (a list of courses).
alreadyExistsIn(CourseName,[course(ListName,_)|T]) :-
    CourseName = ListName;
    alreadyExistsIn(CourseName,T).
alreadyExistsIn(RoomName,[room(ListName,_)|T]) :-
    RoomName = ListName;
    alreadyExistsIn(RoomName,T).