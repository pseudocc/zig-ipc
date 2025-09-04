const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    const server_module = b.createModule(.{
        .root_source_file = b.path("server.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const server = b.addExecutable(.{
        .name = "ipc-server",
        .root_module = server_module,
    });
    b.installArtifact(server);

    const client_module = b.createModule(.{
        .root_source_file = b.path("client.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const client = b.addExecutable(.{
        .name = "ipc-client",
        .root_module = client_module,
    });
    b.installArtifact(client);
}
