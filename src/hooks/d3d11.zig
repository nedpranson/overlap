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
});

const Resource = struct {
    tex: *d3d11.ID3D11Texture2D,
    srv: *d3d11.ID3D11ShaderResourceView,
    modified: u16,

    pub fn deinit(res: Resource) void {
        res.srv.Release();
        res.tex.Release();
    }
};

const Instance = struct {
    device: graphics.d3d11.Device,

    //resources: SynchronizedHashMap(*const Image, Resource),
    //unloaded_resources: SynchronizedArrayList(u32),

    fn deinit(self: *Instance) void {
        //var it = self.resources.valueIterator();
        //defer it.done();

        //while (it.next()) |v| v.deinit();

        //self.resources.deinit(allocator);
        self.device.deinit();
    }
};

allocator: Allocator,
instance_map: SynchronizedHashMap(*const dxgi.IDXGISwapChain, Instance),

var release: *@TypeOf(Release) = undefined;
var present: *@TypeOf(Present) = undefined;
var resize_buffers: *@TypeOf(ResizeBuffers) = undefined;

var zelf: ?@This() = null;

// todo: make it global or sum
// var fr: @import("../graphics/FontRenderer.zig") = undefined;

pub fn attach(gpa: Allocator, d3d11_lib: windows.HMODULE) bool {
    assert(zelf == null);

    // todo: implement valid global! font renderer
    //fr = @import("../graphics/FontRenderer.zig").init(std.heap.page_allocator) catch return false;

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

    zelf = .{
        .instance_map = .empty,
        .allocator = gpa,
    };

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
        ins.deinit();
    }

    hook.instance_map.deinit(hook.allocator);

    windows.FreeConsole() catch {};
    zelf = null;
}

// can be called from any thread
// very dangerous function
// maybe have an array list of like unresolved images
// and after device render we could try to free some of it
// can be even called when hook is not active
pub fn unloadImage(id: u32) void {
    // zelf is not thread safe
    const hook = &(zelf orelse return);

    var it = hook.instance_map.valueIterator();
    defer it.done();

    while (it.next()) |ins| {
        // not thread safe still as srv can be needed
        if (ins.resources.fetchRemove(id)) |res| {
            res.value.deinit();
        }
    }
}

// todo: need to make this threadsafe!!!
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
            instance.deinit();
        }
    }

    return refs;
}

// point is so we that we only pass instructions what and where to draw
// and it is up to the backend/hook impl to draw it

// for handling image resources we can do like
// key as ptr to Image
// and we can add an event like make/destroy image and do some stuff based on it idk

const ImageCache = struct {
    tex: *d3d11.ID3D11Texture2D,
    srv: *d3d11.ID3D11ShaderResourceView,
    modified: u16,
};

fn requestSRV(ctx: *anyopaque, img: *Image) *anyopaque {
    const ins: *Instance = @ptrCast(@alignCast(ctx));
    const allocator = zelf.?.allocator;

    img.mu.lock();
    defer img.mu.unlock();

    // todo: handle err
    const res = ins.resources.getOrPut(allocator, img) catch unreachable;
    defer res.done();

    // img is still not thread safe as pointer can change any time
    if (!res.found_existing) {
        // tood: we can add like a ref to the img here!
        // to notify that our backend is using this resource and it would be unsafe to release it!

        @branchHint(.unlikely);
        const tex, const srv = ins.device.loadImage(img);

        res.value_ptr.* = .{
            .tex = tex,
            .srv = srv,
            .modified = img.modified,
        };
    }

    if (img.usage == .dynamic) {
        if (res.value_ptr.modified != img.modified) {
            ins.device.updateImage(res.value_ptr.tex, img);
            res.value_ptr.modified = img.modified;
        }
    }

    return res.value_ptr.srv;
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
            };
        }

        break :blk result.value_ptr;

    } orelse return present(pSwapChain, SyncInterval, Flags);

    const static = struct {
        threadlocal var draw_commands: [shared.max_draw_commands]shared.DrawCommand = undefined;
        threadlocal var draw_verticies: [shared.max_verticies]shared.DrawVertex = undefined;
        threadlocal var draw_indicies: [shared.max_indicies]shared.DrawIndex = undefined;
    };

    var gui: Gui = .init(
        &static.draw_commands,
        &static.draw_verticies,
        &static.draw_indicies,
        //&fr,
        //ins,
        //&requestSRV,
    );

    renderer.render(&gui);

    // todo: on any error we need to unhhok ourselfs
    instance.device.render(gui.draw_verticies.items, gui.draw_indecies.items, gui.draw_commands.items) catch |err| {
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
        instance.deinit();
    } else {
        return resize_buffers(pSwapChain, BufferCount, Width, Height, NewFormat, SwapChainFlags);
    }

    const hr = resize_buffers(pSwapChain, BufferCount, Width, Height, NewFormat, SwapChainFlags);
    if (hr == windows.S_OK) {
        const device = graphics.d3d11.Device.init(pSwapChain) catch |err| {
            log.err("Device: failed to initialize: {}", .{err});
            return hr;
        };

        hook.instance_map.put(hook.allocator, pSwapChain, .{ .device = device }) catch {
            device.deinit();
            return hr;
        };
    }

    return hr;
}
