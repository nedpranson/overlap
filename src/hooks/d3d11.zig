const std = @import("std");
const windows = @import("../windows.zig");
const detours = @import("../detours.zig");
const hooks = @import("../hooks.zig");
const graphics = @import("../graphics.zig");
const Gui = @import("../Gui2.zig");
const renderer = @import("../renderer.zig");

const d3d11 = windows.d3d11;
const dxgi = windows.dxgi;
const d3dcommon = windows.d3dcommon;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Thread = std.Thread;

pub const interface: hooks.Hook = .{
    .attach = attach,
    .detach = detach,
};

var mutex: Thread.Mutex = .{};

var device_map: std.AutoArrayHashMapUnmanaged(*dxgi.IDXGISwapChain, graphics.d3d11.Device) = .empty;

var present: *@TypeOf(Present) = undefined;
var resize_buffers: *@TypeOf(ResizeBuffers) = undefined;

var hooked = false;

pub fn attach(d3d11_lib: windows.HMODULE) bool {
    assert(hooked == false);

    windows.AllocConsole() catch {};

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

    var failure = true;

    device_map = .empty;

    present = @constCast(@ptrCast(swap_chain.vtable[8]));
    resize_buffers = @constCast(@ptrCast(swap_chain.vtable[13]));

    defer if (failure) {
        present = undefined;
        resize_buffers = undefined;
    };

    detours.attach(Present, &present) catch |err| {
        std.log.err("d3d11: Present: failed to attach: {}", .{err});
        return false;
    };
    std.log.info("d3d11: Present: successfully attached", .{});

    defer if (failure) detours.detach(Present, &present) catch |err| {
        std.log.err("d3d11: Present: cannot detach: {}", .{err});
    };

    detours.attach(ResizeBuffers, &resize_buffers) catch |err| {
        std.log.err("d3d11: ResizeBuffers: failed to attach: {}", .{err});
        return false;
    };
    std.log.info("d3d11: ResizeBuffers: successfully attached", .{});

    defer if (failure) detours.detach(ResizeBuffers, &resize_buffers) catch |err| {
        std.log.err("d3d11: ResizeBuffers: cannot detach: {}", .{err});
    };

    failure = false;
    hooked = true;

    return true;
}

pub fn detach() void {
    assert(hooked == true);

    defer present = undefined;
    defer resize_buffers = undefined;

    detours.detach(Present, &present) catch |err| {
        std.log.err("d3d11: Present: cannot detach: {}", .{err});
    };

    detours.detach(ResizeBuffers, &resize_buffers) catch |err| {
        std.log.err("d3d11: ResizeBuffers: cannot detach: {}", .{err});
    };

    for (device_map.values()) |device| {
        device.deinit();
    }
    device_map.deinit(std.heap.page_allocator);
}

pub fn active() bool {
    return hooked;
}

fn Release(pIUnknown: *windows.IUnknown) callconv(.winapi) windows.ULONG {
    mutex.lock();
    if (device_map.fetchSwapRemove(@ptrCast(pIUnknown))) |kv| {
        kv.value.deinit();
    }
    mutex.unlock();

    //const refs = global.?.release(pIUnknown);
    //return refs;

    return 0;
}

// point is so we that we only pass instructions what and where to draw
// and it is up to the backend/hook impl to draw it

// for handling image resources we can do like
// key as ptr to Image
// and we can add an event like make/destroy image and do some stuff based on it idk

fn Present(
    pSwapChain: *dxgi.IDXGISwapChain,
    SyncInterval: windows.UINT,
    Flags: windows.UINT,
) callconv(.winapi) windows.HRESULT {
    const device = blk: {
        mutex.lock();

        if (device_map.get(pSwapChain)) |device| {
            @branchHint(.likely);

            mutex.unlock();
            break :blk device;
        }

        const device = graphics.d3d11.Device.init(pSwapChain) catch {
            mutex.unlock();
            return present(pSwapChain, SyncInterval, Flags);
        };

        device_map.put(std.heap.page_allocator, pSwapChain, device) catch {
            mutex.unlock();
            device.deinit();
            return present(pSwapChain, SyncInterval, Flags);
        };

        mutex.unlock();
        break :blk device;
    };

    var gui: Gui = .init;
    renderer.render(&gui);

    // if errors maybe we should detach d3d11
    // rename to present
    device.render(gui.draw_verticies.slice(), gui.draw_indecies.slice(), gui.draw_commands.slice()) catch |err| {
        std.log.err("render failed: {}", .{err});
    };

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
    blk: {
        mutex.lock();

        if (device_map.fetchSwapRemove(pSwapChain)) |kv| {
            mutex.unlock();
            kv.value.deinit();
            break :blk;
        }

        mutex.unlock();
        return resize_buffers(pSwapChain, BufferCount, Width, Height, NewFormat, SwapChainFlags);
    }
    
    const hr = resize_buffers(pSwapChain, BufferCount, Width, Height, NewFormat, SwapChainFlags);

    if (hr == windows.S_OK) {
        const device = graphics.d3d11.Device.init(pSwapChain) catch {
            return hr;
        };

        mutex.lock();
        defer mutex.unlock();

        device_map.putAssumeCapacity(pSwapChain, device);
    }

    return hr;
}
