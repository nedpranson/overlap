const std = @import("std");
const gfx = @import("../graphics.zig");
const windows = @import("../windows.zig");
const detours = @import("../detours.zig");

const d3d11 = windows.d3d11;
const dxgi = windows.dxgi;
const d3dcommon = windows.d3dcommon;

const Io = std.Io;
const Allocator = std.mem.Allocator;

const assert = std.debug.assert;

const Hook = struct {
    io: Io,
    gpa: Allocator,

    rl: Io.RwLock,
    swapchain_map: std.array_hash_map.Auto(*dxgi.IDXGISwapChain, BackendHandle),

    release: *@TypeOf(Release),
    present: *@TypeOf(Present),
    resize_buffers: *@TypeOf(ResizeBuffers),
};

var hook: ?Hook = null;

pub fn init(io: Io, gpa: Allocator) !void {
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

    var release = @constCast(swap_chain.vtable.Release);
    var present = @constCast(swap_chain.vtable.Present);
    var resize_buffers = @constCast(swap_chain.vtable.ResizeBuffers);

    try detours.TransactionBegin();
    errdefer detours.TransactionAbort() catch {};

    // todo: update thread

    try detours.Attach(Release, &release);
    try detours.Attach(Present, &present);
    try detours.Attach(ResizeBuffers, &resize_buffers);

    try detours.TransactionCommit();

    assert(hook == null);
    hook = .{
        .io = io,
        .gpa = gpa,
        .rl = .init,
        .swapchain_map = .empty,
        .release = release,
        .present = present, 
        .resize_buffers = resize_buffers,
    };
}

pub fn deinit() !void {
    const h = current();

    try detours.TransactionBegin();
    errdefer detours.TransactionAbort() catch {};

    // todo: update thread

    try detours.Detach(Release, &h.release);
    try detours.Detach(Present, &h.present);
    try detours.Detach(ResizeBuffers, &h.resize_buffers);

    try detours.TransactionCommit();

    for (h.swapchain_map.values()) |b| {
        b.deinit(h.gpa);
    }
    h.swapchain_map.deinit(h.gpa);
}

inline fn current() *Hook {
    return &hook.?;
}

const BackendHandle = struct {
    interface: *gfx.Backend,
    deinitfn: *const fn (*gfx.Backend, gpa: Allocator) void,

    pub fn wrap(backend: anytype) BackendHandle {
        const T = switch (@typeInfo(@TypeOf(backend))) {
            .pointer => |p| p.child,
            else => @compileError("wrap expects a pointer"),
        };

        return .{
            .interface = &backend.interface,
            .deinitfn = struct {
                fn deinit(gfx_backend: *gfx.Backend, gpa: Allocator) void {
                    const b: *T = @alignCast(@fieldParentPtr("interface", gfx_backend));

                    b.deinit();
                    gpa.destroy(b);
                }
            }.deinit,
        };
    }

    inline fn deinit(h: BackendHandle, gpa: Allocator) void {
        h.deinitfn(h.interface, gpa);
    }
};

fn Release(pSwapChain: *dxgi.IDXGISwapChain) callconv(.winapi) windows.ULONG {
    const h = current();
    const refs = h.release(pSwapChain);

    if (refs == 0) {

        // pSwapChain is now invalid and should never be dereferenced
        h.rl.lockUncancelable(h.io);
        defer h.rl.unlock(h.io);

        if (h.swapchain_map.fetchSwapRemove(pSwapChain)) |kv| {
            kv.value.deinit(h.gpa);
        }
    }

    return refs;
}

fn Present(
    pSwapChain: *dxgi.IDXGISwapChain,
    SyncInterval: windows.UINT,
    Flags: windows.UINT,
) callconv(.winapi) windows.HRESULT {
    const h = current();

    const viewport = blk: {
        var desc: dxgi.DXGI_SWAP_CHAIN_DESC = undefined;
        var rect: windows.RECT = undefined;

        assert(pSwapChain.vtable.GetDesc(pSwapChain, &desc) == windows.S_OK);
        // todo: remove this intFromEnum non sence
        if (windows.user32.GetWindowRect(desc.OutputWindow, &rect) == .FALSE) return @intFromEnum(d3d11.D3D11_ERROR.INVALID_CALL);
        
        break :blk gfx.Viewport{
            .width = @intCast(rect.right - rect.left),
            .height = @intCast(rect.bottom - rect.top),
        };
    };

    const backend = (blk: {
        h.rl.lockSharedUncancelable(h.io);
        defer h.rl.unlockShared(h.io);

        break :blk h.swapchain_map.get(pSwapChain);
    } orelse blk: {
        @branchHint(.unlikely);

        const backend = h.gpa.create(gfx.d3d11.Backend) catch return windows.E_OUTOFMEMORY;
        backend.* = gfx.d3d11.Backend.init(pSwapChain) catch @panic("todo");

        const handle: BackendHandle = .wrap(backend);
        
        h.rl.lockUncancelable(h.io);
        defer h.rl.unlock(h.io);

        h.swapchain_map.put(h.gpa, pSwapChain, handle) catch {
            handle.deinit(h.gpa);
            return windows.E_OUTOFMEMORY;
        };

        break :blk handle;
    }).interface;

    // todo: move to threadlocal storage?
    var draw_commands: [gfx.max_draw_commands]gfx.DrawCommand = undefined;
    var draw_verticies: [gfx.max_verticies]gfx.DrawVertex = undefined;
    var draw_indecies: [gfx.max_indicies]gfx.DrawIndex = undefined;

    const wp = backend.vtable.image(backend, .{
        .data = &.{0xFF},
        .width = 1,
        .height = 1,
    }) catch return windows.E_OUTOFMEMORY;
    defer wp.deinit(wp);
    
    var surface: gfx.Surface = .init(
        &draw_commands,
        &draw_verticies,
        &draw_indecies,
        wp,
    );

    surface.rect(.{ 0.0, 0.0 }, .{ 1920.0, 1080.0 }, 0xFFFFFFFF);

    backend.viewport = viewport;
    backend.vtable.draw(backend, &surface);

    return h.present(pSwapChain, SyncInterval, Flags);
}

fn ResizeBuffers(
    pSwapChain: *dxgi.IDXGISwapChain,
    BufferCount: windows.UINT,
    Width: windows.UINT,
    Height: windows.UINT,
    NewFormat: dxgi.DXGI_FORMAT,
    SwapChainFlags: windows.UINT,
) callconv(.winapi) windows.HRESULT {
    const h = current();
    const result = h.resize_buffers(pSwapChain, BufferCount, Width, Height, NewFormat, SwapChainFlags);

    if (result == windows.S_OK) {
        // resize
    }

    return result;
}
