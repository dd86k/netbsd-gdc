import core.sys.posix.sys.types : time_t, clock_t, suseconds_t;
import core.stdc.config : c_long;

// Verify time_t is always 64-bit (D long), not c_long
static assert(time_t.sizeof == 8, "time_t must be 8 bytes (64-bit)");
static assert(is(time_t == long), "time_t must be D long, not c_long");

// Verify clock_t is uint (not c_long)
static assert(clock_t.sizeof == 4, "clock_t must be 4 bytes");
static assert(is(clock_t == uint), "clock_t must be uint");

// Verify suseconds_t is int (not c_long)
static assert(suseconds_t.sizeof == 4, "suseconds_t must be 4 bytes");
static assert(is(suseconds_t == int), "suseconds_t must be int");

import core.sys.posix.time;
import core.sys.posix.sys.time;

void main() {
    import std.stdio;

    // Test time_t: call clock_gettime (pragma mangle -> __clock_gettime50)
    timespec ts;
    int r = clock_gettime(CLOCK_MONOTONIC, &ts);
    assert(r == 0, "clock_gettime failed");
    assert(ts.tv_sec > 0, "clock_gettime returned zero seconds");
    writefln("clock_gettime: %d.%09d", ts.tv_sec, ts.tv_nsec);

    // Test timeval (uses time_t + suseconds_t)
    timeval tv;
    r = gettimeofday(&tv, null);
    assert(r == 0, "gettimeofday failed");
    assert(tv.tv_sec > 1_000_000_000, "gettimeofday sec too small (not 64-bit?)");
    writefln("gettimeofday:  %d.%06d", tv.tv_sec, tv.tv_usec);

    // Test clock() returns clock_t (uint)
    import core.sys.posix.stdc.time : clock, CLOCKS_PER_SEC;
    clock_t c = clock();
    writefln("clock():       %u (CLOCKS_PER_SEC=%u)", c, CLOCKS_PER_SEC);

    // Test nanosleep (pragma mangle -> __nanosleep50)
    timespec req = timespec(0, 1_000_000); // 1ms
    timespec rem;
    r = nanosleep(&req, &rem);
    assert(r == 0, "nanosleep failed");
    writeln("nanosleep:     OK (1ms)");

    // Test clock_getres (pragma mangle -> __clock_getres50)
    timespec res;
    r = clock_getres(CLOCK_MONOTONIC, &res);
    assert(r == 0, "clock_getres failed");
    writefln("clock_getres:  %d.%09d", res.tv_sec, res.tv_nsec);

    writeln("\nAll type and mangle tests PASSED");
}
