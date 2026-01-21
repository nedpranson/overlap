const std = @import("std");

const windows = @import("../windows.zig");
const detours = @import("../detours.zig");
const hooks = @import("../hooks.zig");
const graphics = @import("../graphics.zig");
const renderer = @import("../renderer.zig");
const shared = @import("../graphics/shared.zig");
const Gui = @import("../Gui.zig");
const Image = @import("../graphics/Image.zig");
const SynchronizedHashMap = @import("../util.zig").SynchronizedHashMap;
const SynchronizedArrayList = @import("../util.zig").SynchronizedArrayList;

const d3d11 = windows.d3d11;
const dxgi = windows.dxgi;
const d3dcommon = windows.d3dcommon;
const log = std.log.scoped(.d3d11);
const Allocator = std.mem.Allocator;
const Thread = std.Thread;
const assert = std.debug.assert;

pub const interface: hooks.Hook = .define("d3d11.dll", .{
    .attach = &attach,
    .detach = &detach,
    .active = &active,
    .unload_image = &unloadImage,
});

const Instance = struct {
    device: graphics.d3d11.Device,
    resources: SynchronizedHashMap(*Image, Image.Resource),

    fn deinit(self: *Instance, gpa: Allocator) void {
        var it = self.resources.valueIterator();
        while (it.next()) |resource| {
            @as(*windows.IUnknown, @ptrCast(@alignCast(resource.srv))).Release();
            @as(*windows.IUnknown, @ptrCast(@alignCast(resource.tex))).Release();
        }
        it.done();

        self.resources.deinit(gpa);
        self.device.deinit();

        self.* = undefined;
    }
};

allocator: Allocator,
instance_map: SynchronizedHashMap(*dxgi.IDXGISwapChain, Instance),

var release: *@TypeOf(Release) = undefined;
var present: *@TypeOf(Present) = undefined;
var resize_buffers: *@TypeOf(ResizeBuffers) = undefined;

var zelf: ?@This() = null;

pub fn attach(gpa: Allocator, d3d11_lib: windows.HMODULE) bool {
    assert(zelf == null);

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
        log.err("could not make dummy window: {}", .{err});
        return false;
    };
    defer windows.DestroyWindow(window);

    const D3D11CreateDeviceAndSwapChain = *const @TypeOf(d3d11.D3D11CreateDeviceAndSwapChain);
    const d3d11_create_device_and_swap_chain: D3D11CreateDeviceAndSwapChain = @ptrCast(windows.GetProcAddress(
        d3d11_lib,
        "D3D11CreateDeviceAndSwapChain",
    ) catch |err| {
        log.err("D3D11CreateDeviceAndSwapChain: failed to get proc address: {}", .{err});
        return false;
    });

    var sd = std.mem.zeroes(dxgi.DXGI_SWAP_CHAIN_DESC);
    sd.BufferCount = 1;
    sd.BufferDesc.Format = dxgi.DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.OutputWindow = window;
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
            log.err("D3D11CreateDeviceAndSwapChain failed: {}", .{d3d11.unexpectedError(err)});
            return false;
        },
    }

    defer swap_chain.Release();
    defer device.Release();
    defer device_context.Release();

    var failure = true;

    release = @ptrCast(@constCast(swap_chain.vtable[2]));
    present = @ptrCast(@constCast(swap_chain.vtable[8]));
    resize_buffers = @ptrCast(@constCast(swap_chain.vtable[13]));

    defer if (failure) {
        release = undefined;
        present = undefined;
        resize_buffers = undefined;
    };

    zelf = .{
        .instance_map = .empty,
        .allocator = gpa,
    };
    defer if (failure) {
        var hook = &zelf.?;

        var it = hook.instance_map.map.valueIterator();
        while (it.next()) |ins| {
            ins.deinit(hook.allocator);
        }

        hook.instance_map.deinit(hook.allocator);
        zelf = null;
    };

    detours.attach(Release, &release) catch |err| {
        log.err("Release: failed to attach: {}", .{err});
        return false;
    };
    log.info("Release: successfully attached", .{});

    defer if (failure) detours.detach(Release, &release) catch |err| {
        log.err("Release: cannot detach: {}", .{err});
    };

    detours.attach(Present, &present) catch |err| {
        log.err("Present: failed to attach: {}", .{err});
        return false;
    };
    log.info("Present: successfully attached", .{});

    defer if (failure) detours.detach(Present, &present) catch |err| {
        log.err("Present: cannot detach: {}", .{err});
    };

    detours.attach(ResizeBuffers, &resize_buffers) catch |err| {
        log.err("ResizeBuffers: failed to attach: {}", .{err});
        return false;
    };
    log.info("ResizeBuffers: successfully attached", .{});

    defer if (failure) detours.detach(ResizeBuffers, &resize_buffers) catch |err| {
        log.err("ResizeBuffers: cannot detach: {}", .{err});
    };

    failure = false;

    return true;
}

pub fn detach() void {
    const hook = &zelf.?;

    defer release = undefined;
    defer present = undefined;
    defer resize_buffers = undefined;

    if (detours.detach(Release, &release)) {
        log.info("Release: successfully detached", .{});
    } else |err| {
        log.err("Release: cannot detach: {}", .{err});
    }

    if (detours.detach(Present, &present)) {
        log.info("Present: successfully detached", .{});
    } else |err| {
        log.err("Present: cannot detach: {}", .{err});
    }

    if (detours.detach(ResizeBuffers, &resize_buffers)) {
        log.info("ResizeBuffers: successfully detached", .{});
    } else |err| {
        log.err("ResizeBuffers: cannot detach: {}", .{err});
    }

    var it = hook.instance_map.map.valueIterator();
    while (it.next()) |ins| {
        ins.deinit(hook.allocator);
    }

    hook.instance_map.deinit(hook.allocator);

    windows.FreeConsole() catch {};
    zelf = null;
}

pub fn unloadImage(img: *Image) void {
    const hook = &(zelf orelse return);

    var it = hook.instance_map.valueIterator();
    defer it.done();

    while (it.next()) |instance| {
        if (instance.resources.fetchRemove(img)) |kv| {
            @as(*windows.IUnknown, @ptrCast(@alignCast(kv.value.srv))).Release();
            @as(*windows.IUnknown, @ptrCast(@alignCast(kv.value.tex))).Release();
        }
    }
}

pub fn active() bool {
    return zelf != null;
}

fn Release(pSwapChain: *dxgi.IDXGISwapChain) callconv(.winapi) windows.ULONG {
    const hook = &zelf.?;
    const refs = release(pSwapChain);

    if (refs == 0) {
        if (hook.instance_map.fetchRemove(pSwapChain)) |kv| {
            std.debug.print("releasing IDXGISwapChain: {*}\n", .{pSwapChain});
            var instance = kv.value;
            instance.deinit(hook.allocator);
        }
    }

    return refs;
}

fn Present(
    pSwapChain: *dxgi.IDXGISwapChain,
    SyncInterval: windows.UINT,
    Flags: windows.UINT,
) callconv(.winapi) windows.HRESULT {
    const hook = &zelf.?;
    const instance = blk: {
        const result = hook.instance_map.getOrPut(hook.allocator, pSwapChain) catch break :blk null;
        defer result.done();

        if (!result.found_existing) {
            @branchHint(.cold);

            std.debug.print("new IDXGISwapChain: {*}\n", .{pSwapChain});

            const device = graphics.d3d11.Device.init(pSwapChain) catch |err| {
                log.err("Device: failed to initialize: {}", .{err});
                break :blk null;
            };

            result.value_ptr.* = .{
                .device = device,
                .resources = .empty,
            };
        }

        break :blk result.value_ptr;

    } orelse return present(pSwapChain, SyncInterval, Flags);

    const static = struct {
        threadlocal var draw_commands: [shared.max_draw_commands]shared.DrawCommand = undefined;
        threadlocal var draw_verticies: [shared.max_verticies]shared.DrawVertex = undefined;
        threadlocal var draw_indicies: [shared.max_indicies]shared.DrawIndex = undefined;
        
        fn loadSRV(device: *graphics.d3d11.Device, img: *Image) *anyopaque {
            var ins: *Instance = @fieldParentPtr("device", device);

            // todo: handle err!
            const result = ins.resources.getOrPut(zelf.?.allocator, img) catch unreachable;
            defer result.done();

            if (!result.found_existing) {
                @branchHint(.unlikely);

                // todo: handle err!
                const resource = img.loadResource(device) catch unreachable;
                result.value_ptr.* = resource;
            } else {
                // todo: handle err!
                img.syncResource(device, result.value_ptr) catch unreachable;
            }

            return result.value_ptr.srv;
        }
    };

    var gui: Gui = .init(
        &static.draw_commands,
        &static.draw_verticies,
        &static.draw_indicies,
    );

    renderer.render(hook.allocator, &gui);

    // todo: on any error we need to unhhok ourselfs
    instance.device.render(
        gui.draw_verticies.items,
        gui.draw_indecies.items,
        gui.draw_commands.items,
        static.loadSRV,
    ) catch |err| {
        // todo: disable d3d11 hooks on failure
        log.err("Device: failed to render objects: {}", .{err});
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
    const hook = &zelf.?;

    if (hook.instance_map.fetchRemove(pSwapChain)) |kv| {
        var instance = kv.value;
        instance.deinit(hook.allocator);
    } else {
        return resize_buffers(pSwapChain, BufferCount, Width, Height, NewFormat, SwapChainFlags);
    }

    const hr = resize_buffers(pSwapChain, BufferCount, Width, Height, NewFormat, SwapChainFlags);
    if (hr == windows.S_OK) {
        var device = graphics.d3d11.Device.init(pSwapChain) catch |err| {
            log.err("Device: failed to initialize: {}", .{err});
            return hr;
        };

        hook.instance_map.put(hook.allocator, pSwapChain, .{ .device = device, .resources = .empty }) catch {
            device.deinit();
            return hr;
        };
    }

    return hr;
}
