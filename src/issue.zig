pub const IssueState = enum {
    open,
    closed,
    resolved,
};

pub const Issue = struct {
    state: IssueState,
};
