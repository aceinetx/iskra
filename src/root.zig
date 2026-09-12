const std = @import("std");
const time = @import("time.zig");
const uid = @import("uid.zig");
const util = @import("util.zig");
const Dir = std.Io.Dir;
const Iskra = @import("iskra.zig").Iskra;

const Task = struct {};
const ArgsVector = []const [*:0]const u8;

fn option_new(args: ArgsVector, iskra: *Iskra) void {
    _ = args;
    iskra.new_issue() catch |e| {
        std.log.err("error creating new issue: {}", .{e});
    };
}

const Option = struct {
    name: []const u8,
    func: *const fn (args: ArgsVector, iskra: *Iskra) void,
};

const options: []const Option = &.{
    .{
        .name = "new",
        .func = option_new,
    },
};

pub fn main(init: std.process.Init) !void {
    var iskra = try Iskra.init(Dir.cwd(), init.io, init.gpa);

    const args = init.minimal.args.vector;
    if (args.len <= 1) {
        std.log.err("no arguments provided", .{});
        return;
    }

    for (options) |option| {
        if (util.strcmp(option.name, std.mem.span(args[1]))) {
            option.func(args, &iskra);
            return;
        }
    }

    std.log.err("no such option: {s}", .{args[1]});
}
