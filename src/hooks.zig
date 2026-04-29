const std = @import("std");
const windows = @import("windows.zig");
const detours = @import("detours.zig");

const mem = std.mem;

var load_library_a: *@TypeOf(LoadLibraryA) = undefined;
var load_library_w: *@TypeOf(LoadLibraryW) = undefined;

pub fn init() !void {
    try detours.TransactionBegin();
    errdefer detours.TransactionAbort() catch {};

    const kernel32 = windows.GetModuleHandle("kernel32.dll").?;

    load_library_a = @ptrCast(try windows.GetProcAddress(kernel32, "LoadLibraryA"));
    load_library_w = @ptrCast(try windows.GetProcAddress(kernel32, "LoadLibraryW"));

    std.debug.print("000: load_library_a: {p}\n", .{load_library_a});
    std.debug.print("000: load_library_w: {p}\n", .{load_library_w});

    try detours.Attach(LoadLibraryA, &load_library_a);
    try detours.Attach(LoadLibraryW, &load_library_w);

    try detours.TransactionCommit();

    std.debug.print("111: load_library_a: {p}\n", .{load_library_a});
    std.debug.print("111: load_library_w: {p}\n", .{load_library_w});
}

pub fn deinit() !void {
    try detours.TransactionBegin(); 
    errdefer detours.TransactionAbort() catch {};

    try detours.Detach(LoadLibraryA, &load_library_a);
    try detours.Detach(LoadLibraryW, &load_library_w);

    try detours.TransactionCommit();
}

// if we will hook smth we should update thread from here
fn LoadLibraryA(lpLibFileName: windows.LPCSTR) callconv(.winapi) ?windows.HMODULE {
    const lib = load_library_a(lpLibFileName) orelse return null;
    windows.OutputDebugString(mem.span(lpLibFileName));
    return lib;
}

// if we will hook smth we should update thread from here
fn LoadLibraryW(lpLibFileName: windows.LPCWSTR) callconv(.winapi) ?windows.HMODULE {
    const lib = load_library_w(lpLibFileName) orelse return null;
    windows.OutputDebugStringW(mem.span(lpLibFileName));
    return lib;
}
