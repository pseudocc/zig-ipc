const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    const server = b.addExecutable(.{
        .name = "ipc-server",
        .root_source_file = .{ .path = "server.zig" },
        .target = target,
        .optimize = optimize,
    });
    server.linkLibC();
    b.installArtifact(server);

    const client = b.addExecutable(.{
        .name = "ipc-client",
        .root_source_file = .{ .path = "client.zig" },
        .target = target,
        .optimize = optimize,
    });
    client.linkLibC();
    b.installArtifact(client);
}
