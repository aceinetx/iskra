const std = @import("std");
const time = @import("time.zig");
const uid = @import("uid.zig");

const Task = struct {};

pub fn main(init: std.process.Init) !void {
    try std.Io.Dir.cwd().createDir(init.io, "iskra", .default_dir);
    std.log.info("{}/{}/{} {}:{}:{}", .{
        time.getCurrentYear(),
        time.getCurrentMonth(),
        time.getCurrentDay(),
        time.getCurrentHour(),
        time.getCurrentMinute(),
        time.getCurrentSecond(),
    });

    std.log.info("{s}", .{
        try uid.generateUid(),
    });
}
