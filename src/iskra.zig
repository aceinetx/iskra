const std = @import("std");
const time = @import("time.zig");
const uid = @import("uid.zig");
const util = @import("util.zig");
const issue = @import("issue.zig");

const zon = std.zon;
const Io = std.Io;
const Allocator = std.mem.Allocator;
const Dir = Io.Dir;

pub const Iskra = struct {
    repo_dir: Dir,
    iskra_dir: Dir,
    io: Io,
    allocator: Allocator,

    pub fn init(
        repo_dir: Dir,
        io: Io,
        allocator: Allocator,
    ) !@This() {
        repo_dir.createDir(io, "iskra", .default_dir) catch {};
        const iskra_dir = try repo_dir.openDir(io, "iskra", .{ .iterate = true });

        return .{
            .repo_dir = repo_dir,
            .iskra_dir = iskra_dir,
            .io = io,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.iskra_dir.close(self.io);
    }

    pub fn issueReadState(self: *const @This(), id: []const u8) !issue.IssueState {
        const issue_dir = try self.iskra_dir.createDirPathOpen(self.io, id, .{});
        defer issue_dir.close(self.io);

        const state_file = try issue_dir.openFile(self.io, "state.zon", .{});
        defer state_file.close(self.io);

        const length = try state_file.length(self.io);

        var buffer = try self.allocator.alloc(u8, length + 1);
        defer self.allocator.free(buffer);
        @memset(buffer, 0);

        var file_reader = state_file.reader(self.io, buffer);

        _ = try file_reader.interface.readSliceShort(buffer);

        var diag: zon.parse.Diagnostics = .{};
        defer diag.deinit(self.allocator);

        const state = zon.parse.fromSlice(
            issue.IssueState,
            self.allocator,
            buffer[0 .. buffer.len - 1 :0],
            &diag,
            .{ .ignore_unknown_fields = true },
        ) catch |e| {
            return e;
        };

        return state;
    }

    pub fn issueWriteState(self: *const @This(), id: []const u8, state: issue.IssueState) !void {
        const issue_dir = try self.iskra_dir.createDirPathOpen(self.io, id, .{});
        defer issue_dir.close(self.io);

        const state_file = try issue_dir.createFile(self.io, "state.zon", .{});
        defer state_file.close(self.io);

        var buffer: [1024]u8 = undefined;
        @memset(&buffer, 0);

        var file_writer = state_file.writer(self.io, &buffer);
        const writer = &file_writer.interface;
        try zon.stringify.serialize(state, .{}, writer);

        try writer.flush();
    }

    pub fn issueOpen(self: *const @This(), id: []const u8) !void {
        var state = try self.issueReadState(id);

        state.status = .open;
        try self.issueWriteState(id, state);
    }

    pub fn issueClose(self: *const @This(), id: []const u8) !void {
        var state = try self.issueReadState(id);

        state.status = .closed;
        try self.issueWriteState(id, state);
    }

    pub fn issueResolve(self: *const @This(), id: []const u8) !void {
        var state = try self.issueReadState(id);

        state.status = .resolved;
        try self.issueWriteState(id, state);
    }

    fn issueGrepDir(self: *const @This(), id: []const u8, text: []const u8) !void {
        const issue_dir = try self.iskra_dir.openDir(self.io, id, .{});
        defer issue_dir.close(self.io);

        const issue_file = try issue_dir.openFile(self.io, "ISSUE.md", .{});
        defer issue_file.close(self.io);

        const length = try issue_file.length(self.io);
        const buffer = try self.allocator.alloc(u8, length);
        defer self.allocator.free(buffer);

        _ = try issue_file.readPositionalAll(self.io, buffer, 0);

        if (std.mem.indexOf(u8, buffer, text)) |index| {
            std.log.info("./iskra/{s}/ISSUE.md: {}", .{ id, index });
        }
    }

    pub fn issueGrep(self: *const @This(), text: []const u8) !void {
        var iterator = self.iskra_dir.iterate();
        while (try iterator.next(self.io)) |it| {
            if (it.kind != .directory) continue;
            self.issueGrepDir(it.name, text) catch |e| {
                std.log.err("Error grepping issue {s}: {}", .{ it.name, e });
            };
        }
    }

    pub fn issueNew(self: *const @This()) !void {
        var id_buf = std.mem.zeroes([64]u8);
        const id = try uid.uidBufPrint(&id_buf);

        std.log.debug("Issue ID: {s}", .{id});

        const issue_dir = try self.iskra_dir.createDirPathOpen(self.io, id, .{});
        defer issue_dir.close(self.io);

        const issue_file = try issue_dir.createFile(self.io, "ISSUE.md", .{});
        defer issue_file.close(self.io);

        const state_file = try issue_dir.createFile(self.io, "state.zon", .{});
        defer state_file.close(self.io);

        {
            const text = try std.fmt.allocPrint(self.allocator, "# Issue {s}", .{id});
            defer self.allocator.free(text);

            try issue_file.writeStreamingAll(self.io, text);
        }

        {
            const issue_state = issue.IssueState{
                .status = .open,
            };

            var buffer: [1024]u8 = undefined;
            var file_writer = state_file.writer(self.io, &buffer);
            const writer = &file_writer.interface;
            try zon.stringify.serialize(issue_state, .{}, writer);

            try writer.flush();
        }
    }
};
