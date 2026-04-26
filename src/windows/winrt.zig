const std = @import("std");
const windows = @import("../windows.zig");
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const uuidOf = windows.uuidOf;
const signatureOf = windows.signatureOf;
const uuidFromSignature = windows.uuidFromSignature;

const INT = windows.INT;
const GUID = windows.GUID;
const ULONG = windows.ULONG;
const REFIID = windows.REFIID;
const HRESULT = windows.HRESULT;
const IUnknown = windows.IUnknown;
const IMarshal = windows.IMarshal;
const IAgileObject = windows.IAgileObject;

pub const AsyncStatus = enum(INT) {
    Started = 0,
    Completed = 1,
    Canceled = 2,
    Error = 3,
};

pub fn TypedEventHandler(comptime TSender: type, comptime TResult: type) type {
    return extern struct {
        vtable: *const TypedEventHandlerVTable(TSender, TResult),

        pub const SIGNATURE = "pinterface({9de1c534-6ae1-11e0-84e1-18a905bcc53f}" ++ ";" ++ signatureOf(TSender) ++ ";" ++ signatureOf(TResult) ++ ")";

        pub const UUID = uuidFromSignature(SIGNATURE);

        const Self = @This();

        pub inline fn Release(self: *Self) void {
            IUnknown.Release(@ptrCast(self));
        }

        /// Expects threadsafe allocator
        pub fn init(
            allocator: Allocator,
            context: anytype,
            comptime invokeFn: fn (@TypeOf(context), sender: TSender, args: TResult) void,
        ) Allocator.Error!*Self {
            const Context = @TypeOf(context);
            const Closure = struct {
                vtable: *const TypedEventHandlerVTable(TSender, TResult) = &.{
                    .QueryInterface = &QueryInterface,
                    .AddRef = &AddRef,
                    .Release = &@This().Release,
                    .Invoke = &Invoke,
                },

                allocator: Allocator,
                ref_count: std.atomic.Value(ULONG),

                context: Context,

                fn QueryInterface(ctx: *anyopaque, riid: REFIID, ppvObject: **anyopaque) callconv(.winapi) HRESULT {
                    const self: *@This() = @ptrCast(@alignCast(ctx));

                    const guids = &[_]REFIID{
                        UUID,
                        IUnknown.UUID,
                        IAgileObject.UUID,
                    };

                    if (windows.eqlGuids(riid, guids)) {
                        _ = self.ref_count.fetchAdd(1, .monotonic);

                        ppvObject.* = ctx;
                        return windows.S_OK;
                    }

                    if (mem.eql(u8, mem.asBytes(riid), mem.asBytes(IMarshal.UUID))) {
                        @panic("marshal requested!");
                    }

                    return windows.E_NOINTERFACE;
                }

                // todo: reusize this
                pub fn AddRef(ctx: *anyopaque) callconv(.winapi) ULONG {
                    const self: *@This() = @ptrCast(@alignCast(ctx));

                    const prev = self.ref_count.fetchAdd(1, .monotonic);
                    return prev + 1;
                }

                // todo: reusize this
                fn Release(ctx: *anyopaque) callconv(.winapi) ULONG {
                    const self: *@This() = @ptrCast(@alignCast(ctx));
                    const prev = self.ref_count.fetchSub(1, .release);

                    if (prev == 1) {
                        assert(self.ref_count.load(.acquire) == 0);
                        self.allocator.destroy(self);
                    }

                    return prev - 1;
                }

                pub fn Invoke(ctx: *anyopaque, sender: TSender, args: TResult) callconv(.winapi) HRESULT {
                    const self: *@This() = @ptrCast(@alignCast(ctx));
                    invokeFn(self.context, sender, args);

                    return windows.S_OK;
                }
            };

            const closure = try allocator.create(Closure);
            closure.* = .{
                .allocator = allocator,
                .ref_count = .init(1),
                .context = context,
            };

            return @ptrCast(closure);
        }
    };
}

pub fn TypedEventHandlerVTable(comptime TSender: type, comptime TResult: type) type {
    return extern struct {
        QueryInterface: *const fn (*anyopaque, riid: REFIID, ppvObject: **anyopaque) callconv(.winapi) HRESULT,
        AddRef: *const fn (*anyopaque) callconv(.winapi) ULONG,
        Release: *const fn (*anyopaque) callconv(.winapi) ULONG,
        Invoke: *const fn (*anyopaque, sender: TSender, args: TResult) callconv(.winapi) HRESULT,
    };
}

pub fn IAsyncOperationCompletedHandler(comptime TResult: type) type {
    return extern struct {
        vtable: *const IAsyncOperationCompletedHandlerVTable,

        pub const SIGNATURE = "pinterface({fcdcf02c-e5d8-4478-915a-4d90b74b83a5};" ++ signatureOf(TResult) ++ ")";
        pub const UUID = uuidFromSignature(SIGNATURE);

        pub inline fn Release(self: *IAsyncOperationCompletedHandler(TResult)) void {
            _ = self.vtable.Release(self);
        }

        pub const InvokeError = error{
            OutOfMemory,
            Unexpected,
        };
    };
}

pub const IAsyncOperationCompletedHandlerVTable = extern struct {
    QueryInterface: *const fn (*anyopaque, riid: REFIID, ppvObject: **anyopaque) callconv(.winapi) HRESULT,
    AddRef: *const fn (*anyopaque) callconv(.winapi) ULONG,
    Release: *const fn (*anyopaque) callconv(.winapi) ULONG,
    Invoke: *const fn (*anyopaque, asyncInfo: *IAsyncInfo, status: AsyncStatus) callconv(.winapi) HRESULT,
};

pub const IAsyncInfo = extern struct {
    vtable: [*]const *const anyopaque,

    /// __uuidof(IAsyncInfo) = `"00000036-0000-0000-C000-000000000046"`
    pub const UUID = &GUID{
        .Data1 = 0x00000036,
        .Data2 = 0x0000,
        .Data3 = 0x0000,
        .Data4 = .{
            0xC0, 0x00,
            0x00, 0x00,
            0x00, 0x00,
            0x00, 0x46,
        },
    };

    pub inline fn Release(self: *IAsyncInfo) void {
        IUnknown.Release(@ptrCast(self));
    }

    pub fn get_Status(self: *IAsyncInfo) AsyncStatus {
        const FnType = fn (*IAsyncInfo, *AsyncStatus) callconv(.winapi) HRESULT;
        const get_status: *const FnType = @ptrCast(self.vtable[7]);

        var val: AsyncStatus = undefined;
        assert(get_status(self, &val) == windows.S_OK);

        return val;
    }

    pub fn get_ErrorCode(self: *IAsyncInfo) HRESULT {
        const FnType = fn (*IAsyncInfo, *HRESULT) callconv(.winapi) HRESULT;
        const get_error_code: *const FnType = @ptrCast(self.vtable[8]);

        var errorCode: HRESULT = undefined;
        assert(get_error_code(self, &errorCode) == windows.S_OK);

        return errorCode;
    }

    pub fn Cancel(self: *IAsyncInfo) void {
        const FnType = fn (*IAsyncInfo) callconv(.winapi) HRESULT;
        const cancel: *const FnType = @ptrCast(self.vtable[9]);

        assert(cancel(self) == windows.S_OK);
    }

    pub fn Close(self: *IAsyncInfo) void {
        const FnType = fn (*IAsyncInfo) callconv(.winapi) HRESULT;
        const close: *const FnType = @ptrCast(self.vtable[10]);

        assert(close(self) == windows.S_OK);
    }
};

pub fn IAsyncOperation(comptime T: type) type {
    return extern struct {
        vtable: [*]const *const anyopaque,

        const Self = @This();

        pub inline fn QueryInterface(self: *Self, riid: REFIID, ppvObject: **anyopaque) IUnknown.QueryInterfaceError!void {
            return IUnknown.QueryInterface(@ptrCast(self), riid, ppvObject);
        }

        pub const PutCompletedError = error{Unexpected};

        pub inline fn Release(self: *Self) void {
            IUnknown.Release(@ptrCast(self));
        }

        pub fn Cancel(self: *Self) void {
            var async_info: *IAsyncInfo = undefined;

            self.QueryInterface(IAsyncInfo.UUID, @ptrCast(&async_info)) catch unreachable;
            defer async_info.Release();

            async_info.Cancel();
        }

        pub fn Close(self: *Self) void {
            var async_info: *IAsyncInfo = undefined;

            self.QueryInterface(IAsyncInfo.UUID, @ptrCast(&async_info)) catch unreachable;
            defer async_info.Release();

            async_info.Close();
        }

        pub fn put_Completed(self: *Self, handler: *IAsyncOperationCompletedHandler(T)) PutCompletedError!void {
            const FnType = fn (*Self, *IAsyncOperationCompletedHandler(T)) callconv(.winapi) HRESULT;
            const put_completed: *const FnType = @ptrCast(self.vtable[6]);

            const hr = put_completed(self, handler);
            return switch (hr) {
                windows.S_OK => {},
                else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
            };
        }

        pub const GetResultsError = error{Unexpected};

        pub fn GetResults(self: *Self) GetResultsError!T {
            const FnType = fn (*Self, *T) callconv(.winapi) HRESULT;
            const get_results: *const FnType = @ptrCast(self.vtable[8]);

            var val: T = undefined;

            const hr = get_results(self, &val);
            return switch (hr) {
                windows.S_OK => val,
                else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
            };
        }
    };
}

pub const IRandomAccessStreamReference = extern struct {
    vtable: [*]const *const anyopaque,

    pub inline fn Release(self: *IRandomAccessStreamReference) void {
        IUnknown.Release(@ptrCast(self));
    }

    pub const OpenReadAsyncError = error{Unexpected};

    pub fn OpenReadAsync(self: *IRandomAccessStreamReference) OpenReadAsyncError!*IAsyncOperation(*IRandomAccessStreamWithContentType) {
        const FnType = fn (*IRandomAccessStreamReference, **IAsyncOperation(*IRandomAccessStreamWithContentType)) callconv(.winapi) HRESULT;
        const open_read_async: *const FnType = @ptrCast(self.vtable[6]);

        var operation: *IAsyncOperation(*IRandomAccessStreamWithContentType) = undefined;

        const hr = open_read_async(self, &operation);
        return switch (hr) {
            windows.S_OK => operation,
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }
};

pub const IRandomAccessStreamWithContentType = extern struct {
    vtable: [*]const *const anyopaque,

    pub const SIGNATURE = "{cc254827-4b3d-438f-9232-10c76bc7e038}";

    pub inline fn Release(self: *IRandomAccessStreamWithContentType) void {
        IUnknown.Release(@ptrCast(self));
    }
};
