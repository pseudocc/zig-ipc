const std = @import("std");
const Shared = @import("shared.zig").Shared;

const stdout = std.io.getStdOut().writer();
const N_FILL = 3;
const N_APPEND = 10;
const MAX = 100;

pub fn main() !void {
    var so = try Shared.init("ipc", false);
    defer so.deinit();

    var rng = std.rand.Xoshiro256.init(@intCast(std.time.timestamp()));
    var random = rng.random();

    var numbers: [N_FILL]u32 = undefined;
    for (0..N_FILL) |i| {
        numbers[i] = random.int(u32) % MAX;
    }
    so.fill(&numbers);
    try stdout.print("Filled({d}): {any}\n", .{ N_FILL, numbers });

    var i: i32 = 1;
    while (i <= N_APPEND) : (i += 1) {
        const n = random.int(u32) % MAX;
        so.append(n);
        try stdout.print("Appended({d}): {d}\n", .{ i, n });
    }
}
