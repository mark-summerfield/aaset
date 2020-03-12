/**
 * This module provides storage for a set of items of the same type.
 *
 * The API offers add(), remove(), in (returning a bool for membership),
 * length, and iteration.
 *
 * See the unittest block for examples.
 *
 * Authors: Mark Summerfield, mark@qtrac.eu
 * License: Apache 2.0
 * Copyright © 2020 Mark Summerfield. All rights reserved.
*/
module qtrac.aaset;

/**
 * A collection type that stores items of the same type. The item type
 * must support toHash and ==
*/
struct AAset(T) if (is(int[T])) {
    private {
        alias Unit = void[0];
        enum unit = Unit.init;
        Unit[T] set;
    }

    /** Returns: how many items are in the set */
    size_t length() const { return set.length; }

    /**
     * Adds an item to the set.
     * Params: item to add.
    */
    void add(T item) { set[item] = unit; }

    /**
     * Attempts to remove the given item from the set.
     * Params: item to remove.
     * Returns: true if item present (and therefore removed) or false if
     * the item wasn't present.
    */
    bool remove(T item) { return set.remove(item); }

    /**
     * Provides a range.
     * Returns: a range over the set's items.
    */
    auto range() const { return set.byKey; }
    alias range this;

    /**
     * Supports the `in` operator.
     * Params: item to check for membership in the set.
     * Returns: true if the item is in the set, or false if it isn't.
    */
    bool opBinaryRight(string op: "in")(T lhs) const {
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
