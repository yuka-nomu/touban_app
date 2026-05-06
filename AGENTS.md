\# AGENTS.md



\## Project Overview



This project is a Flutter application for creating school patrol duty schedules.



The application generates monthly schedules and allows manual calendar editing.



\---



\## Tech Stack



\* Flutter

\* Riverpod

\* Hive

\* go\_router

\* Material3



\---



\## Architecture Rules



\* Separate UI and business logic

\* Use Riverpod for state management

\* Use Hive for local storage

\* Keep widget files small

\* Avoid unnecessary abstraction



\---



\## UI Rules



\* Calendar starts on Sunday

\* OFF days are gray-out only

\* Do not display "OFF" text

\* Saturday text is blue

\* Sunday text is red

\* Use BottomSheet for cell editing

\* No horizontal scrolling

\* Cell height is fixed

\* Long names must auto-resize



\---



\## Drag Rules



\* Drag target is member name only

\* Event text does not move

\* Use insert-slide behavior



\---



\## Forbidden



\* Do not add authentication

\* Do not add cloud sync

\* Do not add notifications

\* Do not add PDF export

\* Do not add unnecessary packages

\* Do not refactor unrelated files



\---



\## Documents



Always follow these documents:



\* docs/requirements.md

\* docs/screen\_design.md

\* docs/functional\_spec.md



\---



\## Completion Conditions



\* No compile errors

\* Android build succeeds

\* Null safety enabled

\* Existing features must not break



