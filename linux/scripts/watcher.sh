#!/bin/sh

base="$(dirname "$(readlink -f "$0")")"

cd "${base}"

test() {
	cmake -DCMAKE_BUILD_TYPE=Debug -B ~/raw/tqsl-build -S ~/raw/tqsl && cmake --build ~/raw/tqsl-build && GTEST_COLOR=1 ctest --test-dir ~/raw/tqsl-build/tests/ -V
}

test
while inotifywait --exclude '.*(~|\.sw[p-z])$' --event CLOSE_WRITE -r ~/raw/tqsl/; do
	test
done
