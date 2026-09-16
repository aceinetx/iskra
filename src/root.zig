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
    iskra.issue_new() catch |e| {
        std.log.err("error creating new issue: {}", .{e});
    };
}

fn option_close(args: ArgsVector, iskra: *Iskra) void {
    if (args.len <= 2) {
        std.log.err("no id provided", .{});
        return;
    }

    const id = std.mem.span(args.ptr[2]);
    if (iskra.issue_close(id)) {
        std.log.info("issue {s} closed", .{id});
    } else |e| {
        std.log.err("error closing the issue: {}", .{e});
    }
}

fn option_open(args: ArgsVector, iskra: *Iskra) void {
    if (args.len <= 2) {
        std.log.err("no id provided", .{});
        return;
    }

    const id = std.mem.span(args.ptr[2]);
    if (iskra.issue_open(id)) {
        std.log.info("issue {s} reopened", .{id});
    } else |e| {
        std.log.err("error opening the issue: {}", .{e});
    }
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
    .{
        .name = "close",
        .func = option_close,
    },
    .{
        .name = "open",
        .func = option_open,
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
