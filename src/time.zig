const time = @cImport(@cInclude("time.h"));

pub fn getCurrentYear() i32 {
    const now = time.time(null);
    const tm_ptr = time.gmtime(&now);
    const tm = tm_ptr.*;

    const year = tm.tm_year + 1900;
    return year;
}

pub fn getCurrentMonth() i32 {
    const now = time.time(null);
    const tm_ptr = time.gmtime(&now);
    const tm = tm_ptr.*;

    const month = tm.tm_mon + 1;
    return month;
}

pub fn getCurrentDay() i32 {
    const now = time.time(null);
    const tm_ptr = time.gmtime(&now);
    const tm = tm_ptr.*;

    const day = tm.tm_mday;
    return day;
}

pub fn getCurrentHour() i32 {
    const now = time.time(null);
    const tm_ptr = time.gmtime(&now);
    const tm = tm_ptr.*;

    const day = tm.tm_hour;
    return day;
}

pub fn getCurrentMinute() i32 {
    const now = time.time(null);
    const tm_ptr = time.gmtime(&now);
    const tm = tm_ptr.*;

    const day = tm.tm_min;
    return day;
}

pub fn getCurrentSecond() i32 {
    const now = time.time(null);
    const tm_ptr = time.gmtime(&now);
    const tm = tm_ptr.*;

    const day = tm.tm_sec;
    return day;
}
