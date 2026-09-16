const std = @import("std");
const time = @import("time.zig");
const uid = @import("uid.zig");
const util = @import("util.zig");
const Dir = std.Io.Dir;
const Iskra = @import("iskra.zig").Iskra;

const ArgsVector = []const [*:0]const u8;

const ShiftError = error{InvalidArguments};

fn shiftArgs(args: *ArgsVector, message: []const u8) ShiftError![]const u8 {
    if (args.len == 0) {
        std.log.err("{s}", .{message});
        return ShiftError.InvalidArguments;
    }

    const arg = std.mem.span(args.*[0]);
    args.len -= 1;
    args.ptr += 1;

    return arg;
}

fn request_id(args: *ArgsVector) ShiftError![]const u8 {
    return try shiftArgs(args, "no issue id provided");
}

fn cli(init: std.process.Init) !void {
    var iskra = try Iskra.init(Dir.cwd(), init.io, init.gpa);
    defer iskra.deinit();

    var args = init.minimal.args.vector;

    _ = try shiftArgs(&args, "");

    const action = try shiftArgs(&args, "no action provided");

    if (util.strcmp(action, "new")) {
        iskra.issueNew() catch |e| {
            std.log.err("error creating new issue: {}", .{e});
        };
    } else if (util.strcmp(action, "open")) {
        const id = try request_id(&args);

        if (iskra.issueOpen(id)) {
            std.log.info("issue {s} reopened", .{id});
        } else |e| {
            std.log.err("error opening the issue: {}", .{e});
        }
    } else if (util.strcmp(action, "close")) {
        const id = try request_id(&args);

        if (iskra.issueClose(id)) {
            std.log.info("issue {s} closed", .{id});
        } else |e| {
            std.log.err("error closing the issue: {}", .{e});
        }
    } else if (util.strcmp(action, "resolve")) {
        const id = try request_id(&args);

        if (iskra.issueResolve(id)) {
            std.log.info("issue {s} resolved", .{id});
        } else |e| {
            std.log.err("error resolving the issue: {}", .{e});
        }
    } else if (util.strcmp(action, "stat")) {
        const id = try request_id(&args);

        const state = iskra.issueReadState(id) catch |e| {
            std.log.err("error reading issue state: {}", .{e});
            return;
        };

        std.log.info("Issue {s}", .{id});
        std.log.info("Status: {s}", .{switch (state.status) {
            .open => "Open",
            .closed => "Closed",
            .resolved => "Resolved",
        }});
    } else if (util.strcmp(action, "grep")) {
        const text = try shiftArgs(&args, "no search text provided");

        iskra.issueGrep(text) catch |e| {
            std.log.err("error grepping issues: {}", .{e});
            return;
        };
    } else {
        std.log.err("unknown action: {s}", .{action});
        std.log.err("accepted values are: open | close | resolve | stat", .{});
    }
}

pub fn main(init: std.process.Init) !void {
    cli(init) catch |e| {
        if (e != ShiftError.InvalidArguments) {
            std.log.err("Error: {}", .{e});
        }
    };
}
