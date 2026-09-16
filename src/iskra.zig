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
    pub const IssueCloseError = error{AlreadyClosed};
    pub const IssueOpenError = error{AlreadyOpened};

    repo_dir: Dir,
    iskra_dir: Dir,
    io: Io,
    allocator: Allocator,

    pub fn init(
        repo_dir: Dir,
        io: Io,
        allocator: Allocator,
    ) !@This() {
        const iskra_dir = try repo_dir.createDirPathOpen(io, "iskra", .{});

        return .{
            .repo_dir = repo_dir,
            .iskra_dir = iskra_dir,
            .io = io,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.iskra_dir.close();
    }

    pub fn issue_read_state(self: *const @This(), id: []const u8) !issue.Issue {
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

        return try zon.parse.fromSlice(
            issue.Issue,
            self.allocator,
            buffer[0 .. buffer.len - 1 :0],
            null,
            .{},
        );
    }

    pub fn issue_write_state(self: *const @This(), id: []const u8, state: issue.Issue) !void {
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

    pub fn issue_close(self: *const @This(), id: []const u8) !void {
        var state = try self.issue_read_state(id);
        if (state.state == .closed) {
            return IssueCloseError.AlreadyClosed;
        }

        state.state = .closed;
        try self.issue_write_state(id, state);
    }

    pub fn issue_open(self: *const @This(), id: []const u8) !void {
        var state = try self.issue_read_state(id);
        if (state.state == .open) {
            return IssueOpenError.AlreadyOpened;
        }

        state.state = .open;
        try self.issue_write_state(id, state);
    }

    pub fn issue_new(self: *const @This()) !void {
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
            const issue_state = issue.Issue{
                .state = .open,
            };

            var buffer: [1024]u8 = undefined;
            var file_writer = state_file.writer(self.io, &buffer);
            const writer = &file_writer.interface;
            try zon.stringify.serialize(issue_state, .{}, writer);

            try writer.flush();
        }
    }
};
