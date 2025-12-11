const std = @import("std");
const set = @import("set");
const windows = @import("../windows.zig");
const detours = @import("../detours.zig");
const hooks = @import("../hooks.zig");
const graphics = @import("../graphics.zig");

const d3d11 = windows.d3d11;
const dxgi = windows.dxgi;
const d3dcommon = windows.d3dcommon;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Mutex = std.Thread.Mutex;

const Hook = @This();

pub const interface: hooks.Hook = .{
    .attach = attach,
    .detach = detach,
};

present: *@TypeOf(Present),
resize_buffers: *@TypeOf(ResizeBuffers),

// bug is present is called when self is still null
var self: ?Hook = null;

pub fn attach(d3d11_lib: windows.HMODULE) bool {
    assert(self == null);

    var failure = true;

    const window = windows.CreateWindowEx(
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
    ) catch |err| {
        std.log.err("d3d11: could not make dummy window: {}", .{err});
        return false;
    };
    defer windows.DestroyWindow(window);

    const D3D11CreateDeviceAndSwapChain = *const @TypeOf(d3d11.D3D11CreateDeviceAndSwapChain);
    const d3d11_create_device_and_swap_chain: D3D11CreateDeviceAndSwapChain = @ptrCast(windows.GetProcAddress(
        d3d11_lib,
        "D3D11CreateDeviceAndSwapChain",
    ) catch |err| {
        std.log.err("d3d11: D3D11CreateDeviceAndSwapChain: failed to get proc address: {}", .{err});
        return false;
    });

    var sd = std.mem.zeroes(dxgi.DXGI_SWAP_CHAIN_DESC);
    sd.BufferCount = 1;
    sd.BufferDesc.Format = dxgi.DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.OutputWindow = windows.GetForegroundWindow().?;
    sd.SampleDesc.Count = 1;
    sd.Windowed = windows.TRUE;
    sd.SwapEffect = dxgi.DXGI_SWAP_EFFECT_DISCARD;

    var swap_chain: *dxgi.IDXGISwapChain = undefined;

    var device: *d3d11.ID3D11Device = undefined;
    var device_context: *d3d11.ID3D11DeviceContext = undefined;

    const feature_levels = [_]d3dcommon.D3D_FEATURE_LEVEL{
        d3dcommon.D3D_FEATURE_LEVEL_11_0,
        d3dcommon.D3D_FEATURE_LEVEL_10_1,
        d3dcommon.D3D_FEATURE_LEVEL_10_0,
    };

    const hr = d3d11_create_device_and_swap_chain(
        null,
        d3dcommon.D3D_DRIVER_TYPE_HARDWARE,
        null,
        0,
        &feature_levels,
        feature_levels.len,
        d3d11.D3D11_SDK_VERSION,
        &sd,
        &swap_chain,
        &device,
        null,
        &device_context,
    );

    switch (d3d11.D3D11_ERROR_CODE(hr)) {
        .S_OK => {},
        else => |err| {
            std.log.err("d3d11: D3D11CreateDeviceAndSwapChain failed: {}", .{d3d11.unexpectedError(err)});
            return false;
        },
    }

    defer swap_chain.Release();
    defer device.Release();
    defer device_context.Release();

    var present: *@TypeOf(Present) = @constCast(@ptrCast(swap_chain.vtable[8]));
    var resize_buffers: *@TypeOf(ResizeBuffers) = @constCast(@ptrCast(swap_chain.vtable[13]));

    detours.TransactionBegin() catch |err| {
        std.log.err("d3d11: could not begin the transaction: {}", .{err});
        return false;
    };

    {
        // we dont need this defer tbf
        defer if (failure) {
            detours.TransactionAbort() catch {};
        };

        if (detours.Attach(Present, &present)) {
            std.log.info("d3d11: Present: successfully attached", .{});
        } else |err| {
            std.log.err("d3d11: Present: failed to attach: {}", .{err});
            return false;
        }

        if (detours.Attach(ResizeBuffers, &resize_buffers)) {
            std.log.info("d3d11: ResizeBuffers: successfully attached", .{});
        } else |err| {
            std.log.err("d3d11: ResizeBuffers: failed to attach: {}", .{err});
            return false;
        }
    }

    self = .{
        .present = present,
        .resize_buffers = resize_buffers,
    };

    detours.TransactionCommit() catch |err| {
        std.log.err("d3d11: could not commit the transaction: {}", .{err});

        self = null;
        return false;
    };
    defer if (failure) detach();

    failure = false;
    return true;
}

pub fn detach() void {
    const hook = &self.?;
    defer self = null;

    blk: {
        detours.TransactionBegin() catch |err| {
            std.log.err("d3d11: could not commit the transaction: {}", .{err});
            break :blk;
        };

        if (detours.Detach(Present, &hook.present)) {
            std.log.info("d3d11: Present: successfully deattached", .{});
        } else |err| {
            std.log.err("d3d11: Present: cannot detach: {}", .{err});

            detours.TransactionAbort() catch {};
            break :blk;
        }

        if (detours.Detach(ResizeBuffers, &hook.resize_buffers)) {
            std.log.info("d3d11: ResizeBuffers: successfully deattached", .{});
        } else |err| {
            std.log.err("d3d11: ResizeBuffers: cannot detach: {}", .{err});

            detours.TransactionAbort() catch {};
            break :blk;
        }

        detours.TransactionCommit() catch |err| {
            std.log.err("d3d11: could not commit the transaction: {}", .{err});
            break :blk;
        };
    }
}

pub fn active() bool {
    return self != null;
}

fn Release(pIUnknown: *windows.IUnknown) callconv(.winapi) windows.ULONG {
    _ = pIUnknown;
    //const refs = global.?.release(pIUnknown);
    //return refs;
    return 0;
}

fn Present(
    pSwapChain: *dxgi.IDXGISwapChain,
    SyncInterval: windows.UINT,
    Flags: windows.UINT,
) callconv(.winapi) windows.HRESULT {
    const hook = &self.?;
    return hook.present(pSwapChain, SyncInterval, Flags);
}

fn ResizeBuffers(
    pSwapChain: *dxgi.IDXGISwapChain,
    BufferCount: windows.UINT,
    Width: windows.UINT,
    Height: windows.UINT,
    NewFormat: dxgi.DXGI_FORMAT,
    SwapChainFlags: windows.UINT,
) callconv(.winapi) windows.HRESULT {
    const hook = &self.?;

    const hr = hook.resize_buffers(pSwapChain, BufferCount, Width, Height, NewFormat, SwapChainFlags);
    return hr;
}
