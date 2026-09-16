const std = @import("std");
pub const IssueState = struct {
    pub const Status = enum {
        open,
        closed,
        resolved,
    };

    status: Status = .open,
};
