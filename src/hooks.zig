const std = @import("std");
const windows = @import("windows.zig");
const detours = @import("detours.zig");
const dxgi = @import("hooks/dxgi.zig");

const mem = std.mem;

var load_library_a: *@TypeOf(LoadLibraryA) = undefined;
var load_library_w: *@TypeOf(LoadLibraryW) = undefined;

var thread: windows.HANDLE = undefined;

pub fn init() !void {
    thread = windows.GetCurrentThread();

    // todo: ping unavtive hooks
    // if (windows.GetModuleHandle("d3d11.dll")) |_| {
    //     windows.OutputDebugString("seen d3d11.dll");
    // }

    dxgi.init() catch {};

    try detours.TransactionBegin();
    errdefer detours.TransactionAbort() catch {};

    const kernel32 = windows.GetModuleHandle("kernel32.dll").?;

    load_library_a = @ptrCast(try windows.GetProcAddress(kernel32, "LoadLibraryA"));
    load_library_w = @ptrCast(try windows.GetProcAddress(kernel32, "LoadLibraryW"));

    try detours.Attach(LoadLibraryA, &load_library_a);
    try detours.Attach(LoadLibraryW, &load_library_w);

    try detours.TransactionCommit();
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

    // todo: ping unavtive hooks
    if (windows.GetModuleHandle("d3d11.dll")) |_| {
        windows.OutputDebugString("seen d3d11.dll");
    }

    return lib;
}

// if we will hook smth we should update thread from here
fn LoadLibraryW(lpLibFileName: windows.LPCWSTR) callconv(.winapi) ?windows.HMODULE {
    const lib = load_library_w(lpLibFileName) orelse return null;

    // todo: ping unavtive hooks
    if (windows.GetModuleHandle("d3d11.dll")) |_| {
        windows.OutputDebugString("seen d3d11.dll");
    }

    return lib;
}
