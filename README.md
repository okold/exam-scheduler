# Exam Scheduler
The classic exam scheduling problem, implemented in Java, Prolog, and Haskell for COMP 3649 at Mount Royal University during the Winter 2020 semester. Note that due to the COVID-19 pandemic, which threw everything into disarray right in the middle of the semester, some requirements were relaxed.

## Java
- I did not implement backtracking, so there will be cases where the program will not find a solution that does indeed exist.

## Prolog
- I'm satisfied with this solution, however there are some edge cases that don't get handled properly.
- The program doesn't handle blank empty lines at the end of the text.

## Haskell
- The requirements for IO got significantly relaxed due to the pandemic, so we didn't need to implement reading from files. Instead of the sample files in the sample_inputs folder, the program uses the CourseData and RoomData types within their respective files, which correspond to each room and course data file in the folder.
