# ZIG-IPC

Zig code example to use shared memory among processes, only works on POSIX.

## How it works?

1. Use `shm_open` and `mmap` to create a shared memory block.

1. Use `atomic` operations to manage a boolean value (busy).

    ```zig
    pub inline fn lock(self: *Self, comptime value: bool) void {
        while (true) {
            _ = @cmpxchgStrong(bool, &self.ptr.busy, !value, value, .SeqCst, .SeqCst) orelse break;
        }
    }
    ```

    Updates on the rest memory block requires `busy` to be `false`, and
    set to `true` before the update.

## Run this example

Build and start the server. Press CTRL+C to exit.

```sh
zig build # compiles against v0.11.0
zig-out/bin/ipc-server
```

Start the client in another terminal.

```sh
zig-out/bin/ipc-client
```

### Example output

Server process:
```
pseudoc $ zig-out/bin/ipc-server 
Sorting(3): { 6, 80, 68 }
Sorted(3): { 6, 68, 80 }
Sorting(4): { 6, 68, 80, 87 }
Sorted(4): { 6, 68, 80, 87 }
Sorting(5): { 6, 68, 80, 87, 63 }
Sorted(5): { 6, 63, 68, 80, 87 }
Sorting(6): { 6, 63, 68, 80, 87, 3 }
Sorted(6): { 3, 6, 63, 68, 80, 87 }
Sorting(7): { 3, 6, 63, 68, 80, 87, 86 }
Sorted(7): { 3, 6, 63, 68, 80, 86, 87 }
Sorting(8): { 3, 6, 63, 68, 80, 86, 87, 33 }
Sorted(8): { 3, 6, 33, 63, 68, 80, 86, 87 }
Sorting(9): { 3, 6, 33, 63, 68, 80, 86, 87, 0 }
Sorted(9): { 0, 3, 6, 33, 63, 68, 80, 86, 87 }
Sorting(10): { 0, 3, 6, 33, 63, 68, 80, 86, 87, 13 }
Sorted(10): { 0, 3, 6, 13, 33, 63, 68, 80, 86, 87 }
Sorting(11): { 0, 3, 6, 13, 33, 63, 68, 80, 86, 87, 11 }
Sorted(11): { 0, 3, 6, 11, 13, 33, 63, 68, 80, 86, 87 }
Sorting(12): { 0, 3, 6, 11, 13, 33, 63, 68, 80, 86, 87, 70 }
Sorted(12): { 0, 3, 6, 11, 13, 33, 63, 68, 70, 80, 86, 87 }
Sorting(13): { 0, 3, 6, 11, 13, 33, 63, 68, 70, 80, 86, 87, 25 }
Sorted(13): { 0, 3, 6, 11, 13, 25, 33, 63, 68, 70, 80, 86, 87 }
```

Client process:
```
pseudoc $ zig-out/bin/ipc-client 
Filled(3): { 6, 80, 68 }
Appended(1): 87
Appended(2): 63
Appended(3): 3
Appended(4): 86
Appended(5): 33
Appended(6): 0
Appended(7): 13
Appended(8): 11
Appended(9): 70
Appended(10): 25
```
