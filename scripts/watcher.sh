#!/bin/sh

base="$(dirname "$(readlink -f "$0")")"

cd "${base}"

test() {
	cmake -B ~/raw/tqsl-build -S ~/raw/tqsl && cmake --build ~/raw/tqsl-build && ctest --test-dir ~/raw/tqsl-build/tests/ -V
}

test
while inotifywait --exclude '.*(~|\.sw[a-p])$' --event CLOSE_WRITE -r ~/raw/tqsl/; do
	test
done
