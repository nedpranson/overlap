const std = @import("std");
const gfx = @import("../graphics.zig");
const windows = @import("../windows.zig");
const detours = @import("../detours.zig");

const d3d11 = windows.d3d11;
const dxgi = windows.dxgi;
const d3dcommon = windows.d3dcommon;

const Io = std.Io;
const Allocator = std.mem.Allocator;

// We are not hooking d3d11
// but DXGI as this swapchain will be used by d3d10, d3d11, d3d12

var release: *@TypeOf(Release) = undefined;
var present: *@TypeOf(Present) = undefined;
var resize_buffers: *@TypeOf(ResizeBuffers) = undefined;

var swapchain_map: std.array_hash_map.Auto(*dxgi.IDXGISwapChain, *gfx.Backend) = .empty;
var io: Io = undefined;
var mu: Io.RwLock = .init;
var gpa: Allocator = undefined;

pub fn init() !void {
    const mod = windows.GetModuleHandle("d3d11.dll") orelse return error.ModuleNotFound;

    // todo: get swapchain not only from d3d11
    const D3D11CreateDeviceAndSwapChain = *const @TypeOf(d3d11.D3D11CreateDeviceAndSwapChain);
    const d3d11_create_device_and_swap_chain: D3D11CreateDeviceAndSwapChain = @ptrCast(try windows.GetProcAddress(
        mod,
        "D3D11CreateDeviceAndSwapChain",
    ));

    const window = try windows.CreateWindowEx(
        0,
        "STATIC",
        "Overlap Dummy Window",
        windows.WS_OVERLAPPEDWINDOW,
        windows.CW_USEDEFAULT,
        windows.CW_USEDEFAULT,
        640,
        480,
        null,
        null,
        null,
        null,
    );
    defer windows.DestroyWindow(window);

    var sd = std.mem.zeroes(dxgi.DXGI_SWAP_CHAIN_DESC);
    sd.BufferCount = 1;
    sd.BufferDesc.Format = dxgi.DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.OutputWindow = window;
    sd.SampleDesc.Count = 1;
    sd.Windowed = .TRUE;
    sd.SwapEffect = dxgi.DXGI_SWAP_EFFECT_DISCARD;

    var swap_chain: *dxgi.IDXGISwapChain = undefined;

    var device: *d3d11.ID3D11Device = undefined;
    var device_context: *d3d11.ID3D11DeviceContext = undefined;

    const feature_levels = &[_]d3dcommon.D3D_FEATURE_LEVEL{
        d3dcommon.D3D_FEATURE_LEVEL_11_0,
        d3dcommon.D3D_FEATURE_LEVEL_10_1,
        d3dcommon.D3D_FEATURE_LEVEL_10_0,
    };

    const err = d3d11_create_device_and_swap_chain(
        null,
        d3dcommon.D3D_DRIVER_TYPE_HARDWARE,
        null,
        0,
        feature_levels,
        feature_levels.len,
        d3d11.D3D11_SDK_VERSION,
        &sd,
        &swap_chain,
        &device,
        null,
        &device_context,
    );

    switch (err) {
        .OK => {},
        else => return d3d11.unexpectedError(err),
    }

    defer device_context.Release();
    defer device.Release();
    defer swap_chain.Release();

    release = @constCast(swap_chain.vtable.Release);
    present = @constCast(swap_chain.vtable.Present);
    resize_buffers = @constCast(swap_chain.vtable.ResizeBuffers);

    try detours.TransactionBegin();
    errdefer detours.TransactionAbort() catch {};

    // todo: update thread

    try detours.Attach(Release, &release);
    try detours.Attach(Present, &present);
    try detours.Attach(ResizeBuffers, &resize_buffers);

    try detours.TransactionCommit();
}

pub fn deinit() !void {
    try detours.TransactionBegin();
    errdefer detours.TransactionAbort() catch {};

    // todo: update thread

    try detours.Detach(Release, &release);
    try detours.Detach(Present, &present);
    try detours.Detach(ResizeBuffers, &resize_buffers);

    try detours.TransactionCommit();
}

fn Release(pSwapChain: *dxgi.IDXGISwapChain) callconv(.winapi) windows.ULONG {
    const refs = release(pSwapChain);

    if (refs == 0) {
        // deinit
    }

    return refs;
}

fn Present(
    pSwapChain: *dxgi.IDXGISwapChain,
    SyncInterval: windows.UINT,
    Flags: windows.UINT,
) callconv(.winapi) windows.HRESULT {
    const state = blk: {
        mu.lockSharedUncancelable(io);
        defer mu.unlockShared(io);

        break :blk swapchain_map.get(pSwapChain);
    } orelse blk: {
        @branchHint(.unlikely);

        // if (pSwapChain.GetDevice(d3d11.ID3D11Device)) |device| {
        //     const context = device.GetImmediateContext();
        //
        //     std.debug.print("{}\n", .{device});
        // } else |_| {
        // }

        // create
        // put

        // todo: alloc
        var b: @import("../graphics/backends/D3D11.zig") = .init(undefined);
        const backend = &b.interface;
        
        mu.lockUncancelable(io);
        defer mu.unlock(io);

        swapchain_map.put(gpa, pSwapChain, backend) catch return windows.E_OUTOFMEMORY;
        break :blk backend;
    };

    std.debug.print("{}\n", .{state});

    // init, draw
    return present(pSwapChain, SyncInterval, Flags);
}

fn ResizeBuffers(
    pSwapChain: *dxgi.IDXGISwapChain,
    BufferCount: windows.UINT,
    Width: windows.UINT,
    Height: windows.UINT,
    NewFormat: dxgi.DXGI_FORMAT,
    SwapChainFlags: windows.UINT,
) callconv(.winapi) windows.HRESULT {
    const result = resize_buffers(pSwapChain, BufferCount, Width, Height, NewFormat, SwapChainFlags);

    if (result == windows.S_OK) {
        // resize
    }

    return result;
}
