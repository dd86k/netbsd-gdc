import std.stdio;

void main() {
    // Test statvfs (pragma mangle -> __statvfs90)
    import core.sys.posix.sys.statvfs;
    statvfs_t buf;
    int r = statvfs("/", &buf);
    assert(r == 0, "statvfs failed");
    writefln("statvfs /:     bsize=%u blocks=%u bfree=%u",
        buf.f_bsize, buf.f_blocks, buf.f_bfree);

    // Test select (pragma mangle -> __select50)
    import core.sys.posix.sys.select;
    import core.sys.posix.sys.time : timeval;
    fd_set readfds;
    FD_ZERO(&readfds);
    timeval tv = timeval(0, 0); // immediate timeout
    r = select(0, &readfds, null, null, &tv);
    assert(r == 0, "select failed");
    writeln("select:        OK (immediate timeout)");

    // Test ctime_r, gmtime_r, localtime_r (pragma mangle -> __*50)
    import core.sys.posix.time;
    import core.sys.posix.sys.types : time_t;

    time_t now;
    import core.stdc.time : time;
    now = time(null);
    assert(now > 1_000_000_000, "time() value too small");
    writefln("time():        %d", now);

    // gmtime_r
    tm result;
    tm* gm = gmtime_r(&now, &result);
    assert(gm !is null, "gmtime_r failed");
    writefln("gmtime_r:      %04d-%02d-%02d %02d:%02d:%02d UTC",
        1900 + gm.tm_year, gm.tm_mon + 1, gm.tm_mday,
        gm.tm_hour, gm.tm_min, gm.tm_sec);

    // localtime_r
    tm local_result;
    tm* lt = localtime_r(&now, &local_result);
    assert(lt !is null, "localtime_r failed");
    writefln("localtime_r:   %04d-%02d-%02d %02d:%02d:%02d",
        1900 + lt.tm_year, lt.tm_mon + 1, lt.tm_mday,
        lt.tm_hour, lt.tm_min, lt.tm_sec);

    // ctime_r
    char[26] buf2;
    char* ct = ctime_r(&now, buf2.ptr);
    assert(ct !is null, "ctime_r failed");
    import std.string : fromStringz;
    writefln("ctime_r:       %s", fromStringz(ct));

    // timegm
    tm t2 = result; // copy the gmtime result
    time_t roundtrip = timegm(&t2);
    assert(roundtrip == now, "timegm roundtrip failed");
    writeln("timegm:        roundtrip OK");

    // tzset
    import core.sys.posix.stdc.time : tzset;
    tzset();
    writeln("tzset:         OK");

    // getitimer/setitimer
    import core.sys.posix.sys.time : itimerval, getitimer;
    enum ITIMER_REAL = 0;
    itimerval itv;
    r = getitimer(ITIMER_REAL, &itv);
    assert(r == 0, "getitimer failed");
    writeln("getitimer:     OK");

    writeln("\nAll extended tests PASSED");
}
