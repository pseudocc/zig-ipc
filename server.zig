const std = @import("std");
const c = @cImport(@cInclude("signal.h"));
const Shared = @import("shared.zig").Shared;

const stdout = std.io.getStdOut().writer();

var early_exit = false;
fn handle_abort(_: c_int) callconv(.C) void {
    early_exit = true;
}

pub fn main() !void {
    // CTRL+C to exit
    _ = c.signal(c.SIGINT, &handle_abort);

    var so = Shared.init("ipc", true) catch |e| this: {
        if (e == error.ShareExists) {
            _ = std.c.shm_unlink("ipc");
            break :this try Shared.init("ipc", true);
        }
        return e;
    };
    defer so.deinit();

    var last_length = so.ptr.data.length;
    while (!early_exit) {
        so.lock(true);
        defer so.lock(false);

        if (last_length != so.ptr.data.length) {
            const data = so.ptr.data.numbers[0..so.ptr.data.length];

            try stdout.print("Sorting({d}): {any}\n", .{ data.len, data });
            std.mem.sort(u32, data, {}, std.sort.asc(u32));
            std.time.sleep(std.time.ns_per_ms * 500); // Simulate a slow sort
            try stdout.print("Sorted({d}): {any}\n", .{ data.len, data });

            last_length = so.ptr.data.length;
        }
    }
}
