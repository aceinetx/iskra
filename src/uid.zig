const std = @import("std");
const time = @import("time.zig");

pub fn generateUid() ![64]u8 {
    var buffer = std.mem.zeroes([64]u8);
    const year: u32 = @intCast(time.getCurrentYear());
    const month: u32 = @intCast(time.getCurrentMonth());
    const day: u32 = @intCast(time.getCurrentDay());
    const hour: u32 = @intCast(time.getCurrentHour());
    const minute: u32 = @intCast(time.getCurrentMinute());
    const second: u32 = @intCast(time.getCurrentSecond());

    _ = std.fmt.bufPrint(buffer[0..], "{:04}{:02}{:02}-{:02}{:02}{:02}", .{
        year,
        month,
        day,
        hour,
        minute,
        second,
    }) catch {
        unreachable; // should never run out of space
    };
    return buffer;
}
