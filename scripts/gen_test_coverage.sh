
flutter test --coverage --branch-coverage
genhtml coverage/lcov.info -o coverage/html
genhtml --ignore-errors source,mismatch,inconsistent coverage/lcov.info -o coverage/html --branch-coverage
open coverage/html/index.html