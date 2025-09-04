const std = @import("std");
const Shared = @import("shared.zig").Shared;

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

const N_FILL = 3;
const N_APPEND = 10;
const MAX = 100;

pub fn main() !void {
    var so = try Shared(.client).init("ipc");
    defer so.deinit();

    var rng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
    var random = rng.random();

    var numbers: [N_FILL]u32 = undefined;
    for (0..N_FILL) |i| {
        numbers[i] = random.int(u32) % MAX;
    }
    so.fill(&numbers);
    try stdout.print("Filled({d}): {any}\n", .{ N_FILL, numbers });
    try stdout.flush();

    var i: i32 = 1;
    while (i <= N_APPEND) : (i += 1) {
        const n = random.int(u32) % MAX;
        so.append(n);
        try stdout.print("Appended({d}): {d}\n", .{ i, n });
        try stdout.flush();
    }
}
