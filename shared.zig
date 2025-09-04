const std = @import("std");
const builtin = @import("builtin");
const os = std.posix;

const Role = enum {
    server,
    client,
};

pub fn Shared(comptime role: Role) type {
    return struct {
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

        pub fn init(name: [*:0]const u8) !Self {
            var self: Self = .{
                .name = name,
                .ptr = undefined,
            };

            var oflags: os.O = .{ .ACCMODE = .RDWR };
            if (role == .server) {
                // Create and fail if exists
                oflags.CREAT = true;
                oflags.EXCL = true;
            }

            const mode: os.mode_t = os.S.IWUSR | os.S.IRUSR;
            const rc = shm.open(name, @bitCast(oflags), mode);
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

            if (role == .server) {
                // allocate the shared memory segment
                _ = std.c.ftruncate(rc, @sizeOf(Value));
            }

            const prot: u32 = os.PROT.READ | os.PROT.WRITE;
            const map_flags: os.MAP = .{ .TYPE = .SHARED };
            const raw_data = try os.mmap(null, @sizeOf(Value), prot, map_flags, rc, 0);
            self.ptr = @ptrCast(raw_data);

            if (role == .server) {
                // Initialize the memory
                self.ptr.busy = false;
                self.ptr.data.length = 0;
            }

            return self;
        }

        pub fn deinit(self: *Self) void {
            const raw_data: [*]u8 = @ptrCast(self.ptr);
            os.munmap(@alignCast(raw_data[0..@sizeOf(Value)]));
            if (role == .server) {
                // Remove the shared memory segment
                _ = shm.unlink(self.name);
            }
        }

        pub inline fn lock(self: *Self, comptime value: bool) void {
            while (true) {
                _ = @cmpxchgStrong(bool, &self.ptr.busy, !value, value, .seq_cst, .seq_cst) orelse break;
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
}
