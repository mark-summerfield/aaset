// Copyright © 2020 Mark Summerfield. All rights reserved.
module qtrac.aaset;

struct AAset(T) if (is(int[T])) {
    private {
        alias Unit = void[0];
        enum unit = Unit.init;
        Unit[T] set;
    }
    size_t length() const { return set.length; }
    void add(T item) { set[item] = unit; }
    bool remove(T item) { return set.remove(item); }

    auto range() { return set.byKey; }
    alias range this;

    bool opBinaryRight(string op: "in")(T lhs) {
        return (lhs in set) != null;
    }
    // TODO union(), intersection(), difference(), symmetric_difference()
}

unittest {
    import std.algorithm: sort;
    import std.array: array;
    import std.range: enumerate;
    import std.stdio: writeln;
    import std.typecons: Tuple;

    writeln("unittest for the aaset library.");

    alias Pair = Tuple!(int, "count", string, "word");

    immutable inputs = [Pair(1, "one"), Pair(2, "two"), Pair(3, "three"),
                        Pair(4, "four"), Pair(4, "two"), Pair(5, "five"),
                        Pair(6, "six")];
    AAset!string words;
    assert(words.length == 0);
    foreach (pair; inputs) {
        words.add(pair.word);
        assert(words.length == pair.count);
    }
    immutable len = words.length;
    assert(!words.remove("missing"));
    assert(words.remove("one"));
    assert(words.length == len - 1);
    immutable expected = ["five", "four", "six", "three", "two"];
    foreach (i, word; words.array.sort.enumerate)
        assert(word == expected[i]);
    assert("Z" !in words);
    assert("three" in words);
}

