const std = @import("std");
const builtin = @import("builtin");
const os = std.os;

pub const Shared = struct {
    const Self = @This();

    const shm = struct {
        pub const open = std.c.shm_open;
        pub const unlink = std.c.shm_unlink;
    };

    pub const Data = struct {
        length: u32,
        numbers: [31]u32,
    };

    const Value = struct {
        busy: bool,
        data: Data,
    };

    name: [*:0]const u8,
    ptr: *Value,
    create: bool,

    pub fn init(name: [*:0]const u8, comptime create: bool) !Self {
        var self: Self = .{
            .name = name,
            .ptr = undefined,
            .create = create,
        };

        var oflags: c_int = os.O.RDWR;
        if (create) {
            oflags |= os.O.CREAT | os.O.EXCL;
        }

        const rc = shm.open(name, oflags, os.S.IWUSR | os.S.IRUSR);
        if (rc < 0) {
            return switch (os.errno(rc)) {
                .ACCES => error.AccessDenied,
                .EXIST => error.ShareExists,
                .INVAL => error.InvalidName,
                .MFILE, .NFILE => error.TooManyFiles,
                .NAMETOOLONG => error.NameTooLong,
                else => unreachable,
            };
        }

        if (create) {
            _ = std.c.ftruncate(rc, @sizeOf(Value));
        }

        const raw_data = try os.mmap(null, @sizeOf(Value), os.PROT.READ | os.PROT.WRITE, os.MAP.SHARED, rc, 0);
        self.ptr = @ptrCast(raw_data);

        if (create) {
            self.ptr.busy = false;
            self.ptr.data.length = 0;
        }

        return self;
    }

    pub fn deinit(self: *Self) void {
        const raw_data: [*]u8 = @ptrCast(self.ptr);
        os.munmap(@alignCast(raw_data[0..@sizeOf(Value)]));
        if (self.create) {
            _ = shm.unlink(self.name);
        }
    }

    pub inline fn lock(self: *Self, comptime value: bool) void {
        while (true) {
            _ = @cmpxchgStrong(bool, &self.ptr.busy, !value, value, .SeqCst, .SeqCst) orelse break;
        }
    }

    pub fn fill(self: *Self, data: []const u32) void {
        self.lock(true);
        defer self.lock(false);

        self.ptr.data.length = @intCast(data.len);
        for (data, 0..) |v, i| {
            self.ptr.data.numbers[i] = v;
        }
    }

    pub fn append(self: *Self, value: u32) void {
        self.lock(true);
        defer self.lock(false);

        if (self.ptr.data.length < self.ptr.data.numbers.len) {
            self.ptr.data.numbers[self.ptr.data.length] = value;
            self.ptr.data.length += 1;
        }
    }
};
