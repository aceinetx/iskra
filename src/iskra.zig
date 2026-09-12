const std = @import("std");
const time = @import("time.zig");
const uid = @import("uid.zig");
const util = @import("util.zig");

const Io = std.Io;
const Allocator = std.mem.Allocator;
const Dir = Io.Dir;

pub const Iskra = struct {
    repo_dir: Dir,
    iskra_dir: Dir,
    open_issues_dir: Dir,
    closed_issues_dir: Dir,
    resolved_issues_dir: Dir,
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
            .open_issues_dir = try iskra_dir.createDirPathOpen(io, "open", .{}),
            .closed_issues_dir = try iskra_dir.createDirPathOpen(io, "closed", .{}),
            .resolved_issues_dir = try iskra_dir.createDirPathOpen(io, "resolved", .{}),
            .io = io,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.open_issues_dir.close();
        self.closed_issues_dir.close();
        self.resolved_issues_dir.close();
        self.iskra_dir.close();
    }

    pub fn new_issue(self: *const @This()) !void {
        var id_buf = std.mem.zeroes([64]u8);
        const id = try uid.uidBufPrint(&id_buf);

        std.log.debug("{s}", .{id});

        const issue_dir = try self.open_issues_dir.createDirPathOpen(self.io, id, .{});
        defer issue_dir.close(self.io);

        const issue_file = try issue_dir.createFile(self.io, "ISSUE.md", .{});
        {
            const text = try std.fmt.allocPrint(self.allocator, "# Issue {s}", .{id});
            defer self.allocator.free(text);

            try issue_file.writeStreamingAll(self.io, text);
        }
        defer issue_file.close(self.io);
    }
};
