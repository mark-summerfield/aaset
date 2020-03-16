/**
 * This module provides storage for a set of items of the same type.
 *
 * The API offers add(), remove(), in (returning a bool for membership),
 * clear, length, iteration, dup, and toString.
 *
 * See the unittest block at the end for examples.
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
    /** The maxToStringItems controls how many items are output by
     * toString.
     * If unspecified or 0, all items are output; otherwise at most
     * maxToStringItems are output.
    */
    size_t maxToStringItems = 0; // 0 means unlimited

    private {
        alias Unit = void[0];
        enum unit = Unit.init;
        Unit[T] set;
    }

    /** The constructor.
     * Examples:
     *  AAset!string words;
     *  auto numbers = AAset!int();
     *  auto lowPrimes = AAset!long(2, 3, 5, 7, 11, 13, 19);
     * Params: zero or more items to initialize the set with.
    */
    this(T[] items ...) { add(items); }

    /** Returns: how many items are in the set. */
    size_t length() const { return set.length; }

    /** Returns: true if the set is empty; otherwise false. */
    bool empty() const { return set.length == 0; }

    /**
     * Adds any number of items to the set.
     * Params: item(s) to add.
    */
    void add(T[] items ...) {
        foreach (item; items)
            set[item] = unit;
    }

    /**
     * Attempts to remove the given item from the set.
     * Params: item to remove.
     * Returns: true if item present (and therefore removed) or false if
     * the item wasn't present.
    */
    bool remove(T item) { return set.remove(item); }

    /**
     * Removes all items leaving the set empty.
    */
    void clear() { set.clear; }

    /**
     * Provides a range.
     * Returns: a range over the set's items.
    */
    auto opSlice() const { return set.byKey; }

    /**
     * Returns: a copy (duplicate) of this set.
    */
    auto dup() const {
        import std.algorithm: each;
        AAset!T other;
        other.maxToStringItems = maxToStringItems;
        each!(item => other.add(item))(set.byKey);
        return other;
    }

    /**
     * Provides the `in` operator.
     * Params: item to check for membership in the set.
     * Returns: true if the item is in the set, or false if it isn't.
    */
    bool opBinaryRight(string op: "in")(T lhs) const {
        return (lhs in set) !is null;
    }

    /**
     * Provides the `&` operator.
     * Params: another set (with the same item type) to intersect with.
     * Returns: the intersection of this set and the other set.
    */
    auto opBinary(string op: "&")(ref const AAset!T other) const {
        import std.algorithm: max;
        import std.range: chain;
        AAset!T intersection;
        intersection.maxToStringItems = max(maxToStringItems,
                                            other.maxToStringItems);
        foreach (item; chain(set.byKey, other.set.byKey))
            if (item in set && item in other.set)
                intersection.add(item);
        return intersection;
    }

    /**
     * Provides the `&=` operator.
     * Params: another set (with the same item type) to intersect with.
     * Returns: this set after it has been intersected with the other set.
    */
    auto opOpAssign(string op: "&")(ref const AAset!T other) {
        import std.range: chain;
        foreach (item; chain(set.byKey, other.set.byKey))
            if (item !in set || item !in other.set)
                set.remove(item);
        return this;
    }

    /**
     * Provides the `|` operator.
     * Params: another set (with the same item type) to union with.
     * Returns: the union of this set and the other set.
    */
    auto opBinary(string op: "|")(ref const AAset!T other) const {
        import std.algorithm: each, max;
        import std.range: chain;
        AAset!T unioned;
        unioned.maxToStringItems = max(maxToStringItems,
                                       other.maxToStringItems);
        each!(item => unioned.add(item))(chain(set.byKey, other.set.byKey));
        return unioned;
    }

    /**
     * Provides the `|=` operator.
     * Params: another set (with the same item type) to union with.
     * Returns: this set after it has been unioned with the other set.
    */
    auto opOpAssign(string op: "|")(ref const AAset!T other) {
        import std.algorithm: each;
        each!(item => add(item))(other.set.byKey);
        return this;
    }

    /**
     * Provides a string representation of the set (e.g., for debugging
     * and testing). See maxToStringItems for how to limit how many items
     * can be output (the default of 0 means all of them).
     * Returns: string of the unordered items, e.g., {item2, item1, item3}
     * or {} if the set is empty.
    */
    string toString() const {
        import std.array: appender;
        import std.conv: to;
        import std.range: enumerate;

        if (set.length == 0)
            return "{}";
        auto buffer = appender!string;
        buffer.put('{');
        foreach (i, item; set.byKey.enumerate) {
            if (maxToStringItems != 0 && i == maxToStringItems && 
                   set.length > maxToStringItems) {
                buffer.put(", …");
                break;
            }
            if (i > 0)
                buffer.put(", ");
            buffer.put(item.to!string);
        }
        buffer.put('}');
        return buffer.data;
    }
}

unittest {
    import std.algorithm: sort;
    import std.array: array;
    import std.format: format;
    import std.range: enumerate;
    import std.stdio: writeln;
    import std.typecons: Tuple;

    writeln("unittest for the aaset library.");

    alias Pair = Tuple!(int, "count", string, "word");

    immutable inputs = [Pair(1, "one"), Pair(2, "two"), Pair(3, "three"),
                        Pair(4, "four"), Pair(4, "two"), Pair(5, "five"),
                        Pair(6, "six")];
    AAset!string words;
    assert(words.length == 0 && words.empty);
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
    assert(words.length == 5);
    // Hostage to fortune regarding ordering due to hash algorithm
    assert(words.toString == "{two, four, five, six, three}");
    words.clear;
    assert(words.length == 0 && words.empty);
    assert(words.toString == "{}");
    AAset!int numbers; // -or- auto numbers = AAset!int();
    numbers.maxToStringItems = 15;
    assert(numbers.length == 0 && numbers.empty);
    foreach (x; 10..21)
        numbers.add(x);
    assert(numbers.length == 11);
    // Hostages to fortune regarding ordering due to hash algorithm
    assert(numbers.toString ==
           "{13, 15, 17, 19, 20, 11, 16, 12, 14, 10, 18}");
    foreach (x; 15..35)
        numbers.add(x);
    assert(numbers.toString ==
           "{13, 26, 15, 24, 17, 30, 19, 20, 21, 28, 33, 11, 16, " ~
           "29, 27, …}");
    numbers = AAset!int();
    foreach (x; 1..11)
        numbers.add(x);
    assert(numbers.toString == "{6, 7, 2, 3, 10, 1, 8, 5, 4, 9}");
    numbers = AAset!int();
    numbers.maxToStringItems = 1;
    foreach (x; 1..11)
        numbers.add(x);
    assert(numbers.toString == "{6, …}");
    numbers = AAset!int();
    numbers.maxToStringItems = 2;
    foreach (x; 1..11)
        numbers.add(x);
    assert(numbers.toString == "{6, 7, …}");
    numbers = AAset!int();
    numbers.maxToStringItems = 3;
    foreach (x; 1..11)
        numbers.add(x);
    assert(numbers.toString == "{6, 7, 2, …}");
    numbers = AAset!int(100, 200, 300, 400, 500);
    assert(numbers.length == 5);
    numbers.add(600, 700, 800, 100, 200);
    assert(numbers.length == 8);

    auto one = AAset!int(1, 2, 3, 4, 5, 6);
    const two = AAset!int(2, 4, 6, 8);
    immutable three = one & two;
    assert(three.length == 3 && 2 in three && 4 in three && 6 in three);
    assert(one.length == 6 && 8 !in one);
    one.add(7, 8, 9, 10);
    assert(one.length == 10 && 8 in one);
    one &= two;
    assert(one.length == 4 && 2 in one && 4 in one && 6 in one && 8 in one);

    auto a = AAset!int(1, 2, 3, 4, 5, 6);
    const b = AAset!int(2, 4, 6, 8, 10);
    immutable c = a | b;
    assert(c.length == 8 && 1 in c && 2 in c && 3 in c && 4 in c &&
           5 in c && 6 in c && 8 in c && 10 in c);
    assert(a.length == 6 && 8 !in a && 10 !in a);
    a |= b;
    assert(a.length == 8 && 1 in a && 2 in a && 3 in a && 4 in a &&
           5 in a && 6 in a && 8 in a && 10 in a);
    const x = AAset!long(2, 3, 5, 7, 11);
    assert(x.length == 5 && 2 in x && 3 in x && 5 in x && 6 !in x);
    immutable y = x.dup;
    assert(y.length == 5 && 2 in y && 3 in y && 5 in y && 6 !in y);
    immutable z = one.dup;
    assert(z.length == 4 && 2 in z && 4 in z && 6 in z && 8 in z);
}
