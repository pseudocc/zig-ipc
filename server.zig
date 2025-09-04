const std = @import("std");
const c = @cImport(@cInclude("signal.h"));
const Shared = @import("shared.zig").Shared;

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

var early_exit = false;
fn handleAbort(_: c_int) callconv(.c) void {
    early_exit = true;
}

pub fn main() !void {
    // CTRL+C to exit
    _ = c.signal(c.SIGINT, &handleAbort);

    var so = Shared(.server).init("ipc") catch |e| this: {
        if (e == error.ShareExists) {
            _ = std.c.shm_unlink("ipc");
            break :this try Shared(.server).init("ipc");
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
            try stdout.flush();

            std.mem.sort(u32, data, {}, std.sort.asc(u32));
            std.Thread.sleep(std.time.ns_per_ms * 500); // Simulate a slow sort

            try stdout.print("Sorted({d}): {any}\n", .{ data.len, data });
            try stdout.flush();

            last_length = so.ptr.data.length;
        }
    }
}
