const std = @import("std");
const windows = @import("../../windows.zig");
const winrt = @import("../winrt.zig");
const assert = std.debug.assert;

const INT64 = i64;
const GUID = windows.GUID;
const HRESULT = windows.HRESULT;
const HSTRING = windows.HSTRING;
const IUnknown = windows.IUnknown;
const TimeSpan = windows.TimeSpan;
const IAsyncOperation = windows.IAsyncOperation;
const TypedEventHandler = windows.TypedEventHandler;
const MediaPlaybackStatus = windows.MediaPlaybackStatus;
const IRandomAccessStreamReference = winrt.IRandomAccessStreamReference;

pub const EventRegistrationToken = extern struct {
    value: INT64,
};

pub const IPlaybackInfoChangedEventArgs = extern struct {
    vtable: [*]const *const anyopaque,

    pub const NAME = "Windows.Media.Control.TimelinePropertiesChangedEventArgs";
    pub const SIGNATURE = "rc(" ++ NAME ++ ";{29033a2f-c923-5a77-bcaf-055ff415ad32})";
};

pub const ITimelinePropertiesChangedEventArgs = extern struct {
    vtable: [*]const *const anyopaque,

    pub const NAME = "Windows.Media.Control.TimelinePropertiesChangedEventArgs";
    pub const SIGNATURE = "rc(" ++ NAME ++ ";{29033a2f-c923-5a77-bcaf-055ff415ad32})";
};

pub const IMediaPropertiesChangedEventArgs = extern struct {
    vtable: [*]const *const anyopaque,

    pub const NAME = "Windows.Media.Control.MediaPropertiesChangedEventArgs";
    pub const SIGNATURE = "rc(" ++ NAME ++ ";{7d3741cb-adf0-5cef-91ba-cfabcdd77678})";
};

pub const ICurrentSessionChangedEventArgs = extern struct {
    vtable: [*]const *const anyopaque,

    pub const NAME = "Windows.Media.Control.CurrentSessionChangedEventArgs";
    pub const SIGNATURE = "rc(" ++ NAME ++ ";{6969cb39-0bfa-5fe0-8d73-09cc5e5408e1})";
};

pub const IGlobalSystemMediaTransportControlsSessionMediaProperties = extern struct {
    vtable: [*]const *const anyopaque,

    pub const NAME = "Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties";

    pub const SIGNATURE = "rc(" ++ NAME ++ ";{68856cf6-adb4-54b2-ac16-05837907acb6})";

    pub const UUID = &GUID.parse("{68856cf6-adb4-54b2-ac16-05837907acb6}");

    pub inline fn Release(self: *IGlobalSystemMediaTransportControlsSessionMediaProperties) void {
        IUnknown.Release(@ptrCast(self));
    }

    pub fn get_Title(self: *IGlobalSystemMediaTransportControlsSessionMediaProperties) HSTRING {
        const FnType = fn (self: *IGlobalSystemMediaTransportControlsSessionMediaProperties, *HSTRING) callconv(.winapi) HRESULT;
        const get_title: *const FnType = @ptrCast(self.vtable[6]);

        var title: HSTRING = undefined;
        assert(get_title(self, &title) == windows.S_OK);
        return title;
    }

    pub fn get_Artist(self: *IGlobalSystemMediaTransportControlsSessionMediaProperties) HSTRING {
        const FnType = fn (self: *IGlobalSystemMediaTransportControlsSessionMediaProperties, *HSTRING) callconv(.winapi) HRESULT;
        const get_artist: *const FnType = @ptrCast(self.vtable[9]);

        var artist: HSTRING = undefined;
        assert(get_artist(self, &artist) == windows.S_OK);
        return artist;
    }

    pub const GetThumbnailError = error{Unexpected};

    pub fn get_Thumbnail(self: *IGlobalSystemMediaTransportControlsSessionMediaProperties) GetThumbnailError!?*IRandomAccessStreamReference {
        const FnType = fn (self: *IGlobalSystemMediaTransportControlsSessionMediaProperties, *?*IRandomAccessStreamReference) callconv(.winapi) HRESULT;
        const get_thumbnail: *const FnType = @ptrCast(self.vtable[15]);

        var thumbnail: ?*IRandomAccessStreamReference = undefined;

        const hr = get_thumbnail(self, &thumbnail);
        return switch (hr) {
            windows.S_OK => thumbnail,
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }
};

pub const IGlobalSystemMediaTransportControlsSessionPlaybackInfo = extern struct {
    vtable: [*]const *const anyopaque,

    pub inline fn Release(self: *IGlobalSystemMediaTransportControlsSessionPlaybackInfo) void {
        IUnknown.Release(@ptrCast(self));
    }

    pub fn get_PlaybackStatus(self: *IGlobalSystemMediaTransportControlsSessionPlaybackInfo) MediaPlaybackStatus {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSessionPlaybackInfo, *MediaPlaybackStatus) callconv(.winapi) HRESULT;
        const get_playback_status: *const FnType = @ptrCast(self.vtable[7]);

        var value: MediaPlaybackStatus = undefined;
        assert(get_playback_status(self, &value) == windows.S_OK);

        return value;
    }
};

pub const IGlobalSystemMediaTransportControlsSessionTimelineProperties = extern struct {
    vtable: [*]const *const anyopaque,

    pub inline fn Release(self: *IGlobalSystemMediaTransportControlsSessionTimelineProperties) void {
        IUnknown.Release(@ptrCast(self));
    }

    pub inline fn get_StartTime(self: *IGlobalSystemMediaTransportControlsSessionTimelineProperties) TimeSpan {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSessionTimelineProperties, *TimeSpan) callconv(.winapi) HRESULT;
        const get_start_time: *const FnType = @ptrCast(self.vtable[6]);

        var value: TimeSpan = undefined;
        assert(get_start_time(self, &value) == windows.S_OK);

        return value;
    }

    pub inline fn get_EndTime(self: *IGlobalSystemMediaTransportControlsSessionTimelineProperties) TimeSpan {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSessionTimelineProperties, *TimeSpan) callconv(.winapi) HRESULT;
        const get_end_time: *const FnType = @ptrCast(self.vtable[7]);

        var value: TimeSpan = undefined;
        assert(get_end_time(self, &value) == windows.S_OK);

        return value;
    }

    pub inline fn get_Position(self: *IGlobalSystemMediaTransportControlsSessionTimelineProperties) TimeSpan {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSessionTimelineProperties, *TimeSpan) callconv(.winapi) HRESULT;
        const get_position: *const FnType = @ptrCast(self.vtable[10]);

        var value: TimeSpan = undefined;
        assert(get_position(self, &value) == windows.S_OK);

        return value;
    }
};

pub const IGlobalSystemMediaTransportControlsSession = extern struct {
    vtable: [*]const *const anyopaque,

    pub const NAME = "Windows.Media.Control.GlobalSystemMediaTransportControlsSession";
    pub const SIGNATURE = "rc(" ++ NAME ++ ";{7148c835-9b14-5ae2-ab85-dc9b1c14e1a8})";

    pub const TryGetMediaPropertiesAsyncError = error{Unexpected};

    pub inline fn Release(self: *IGlobalSystemMediaTransportControlsSession) void {
        IUnknown.Release(@ptrCast(self));
    }

    pub const GetSourceAppUserModelIdError = error{
        Unexpected,
    };

    pub fn get_SourceAppUserModelId(self: *IGlobalSystemMediaTransportControlsSession) GetSourceAppUserModelIdError!HSTRING {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSession, *HSTRING) callconv(.winapi) HRESULT;
        const get_source_app_user_model_id: *const FnType = @ptrCast(self.vtable[6]);

        var value: HSTRING = undefined;

        const hr = get_source_app_user_model_id(self, &value);
        return switch (hr) {
            windows.S_OK => value,
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }

    pub fn TryGetMediaPropertiesAsync(
        self: *IGlobalSystemMediaTransportControlsSession,
    ) TryGetMediaPropertiesAsyncError!*IAsyncOperation(*IGlobalSystemMediaTransportControlsSessionMediaProperties) {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSession, **IAsyncOperation(*IGlobalSystemMediaTransportControlsSessionMediaProperties)) callconv(.winapi) HRESULT;
        const try_get_media_properties_async: *const FnType = @ptrCast(self.vtable[7]);

        var operation: *IAsyncOperation(*IGlobalSystemMediaTransportControlsSessionMediaProperties) = undefined;

        const hr = try_get_media_properties_async(self, &operation);
        return switch (hr) {
            windows.S_OK => operation,
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }

    pub const GetTimelinePropertiesError = error{
        Unexpected,
    };

    pub fn GetTimelineProperties(self: *IGlobalSystemMediaTransportControlsSession) GetPlaybackInfoError!*IGlobalSystemMediaTransportControlsSessionTimelineProperties {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSession, **IGlobalSystemMediaTransportControlsSessionTimelineProperties) callconv(.winapi) HRESULT;
        const get_playback_info: *const FnType = @ptrCast(self.vtable[8]);

        var result: *IGlobalSystemMediaTransportControlsSessionTimelineProperties = undefined;

        const hr = get_playback_info(self, &result);
        return switch (hr) {
            windows.S_OK => result,
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }

    pub const GetPlaybackInfoError = error{
        Unexpected,
    };

    pub fn GetPlaybackInfo(self: *IGlobalSystemMediaTransportControlsSession) GetPlaybackInfoError!*IGlobalSystemMediaTransportControlsSessionPlaybackInfo {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSession, **IGlobalSystemMediaTransportControlsSessionPlaybackInfo) callconv(.winapi) HRESULT;
        const get_playback_info: *const FnType = @ptrCast(self.vtable[9]);

        var result: *IGlobalSystemMediaTransportControlsSessionPlaybackInfo = undefined;

        const hr = get_playback_info(self, &result);
        return switch (hr) {
            windows.S_OK => result,
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }

    pub const AddTimelinePropertiesChangedError = error{
        Unexpected,
    };

    pub fn add_TimelinePropertiesChanged(
        self: *IGlobalSystemMediaTransportControlsSession,
        handler: *TypedEventHandler(*IGlobalSystemMediaTransportControlsSession, *ITimelinePropertiesChangedEventArgs),
    ) AddTimelinePropertiesChangedError!EventRegistrationToken {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSession, *TypedEventHandler(*IGlobalSystemMediaTransportControlsSession, *ITimelinePropertiesChangedEventArgs), *EventRegistrationToken) callconv(.winapi) HRESULT;
        const add_timeline_properties_changed: *const FnType = @ptrCast(self.vtable[25]);

        var token: EventRegistrationToken = undefined;

        const hr = add_timeline_properties_changed(self, handler, &token);
        return switch (hr) {
            windows.S_OK => token,
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }

    pub const RemoveTimelinePropertiesChangedError  = error{
        Unexpected,
    };

    pub fn remove_TimelinePropertiesChanged(
        self: *IGlobalSystemMediaTransportControlsSession,
        token: EventRegistrationToken,
    ) RemoveTimelinePropertiesChangedError!void {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSession, EventRegistrationToken) callconv(.winapi) HRESULT;

        const remove_timeline_properties_changed: *const FnType = @ptrCast(self.vtable[26]);
        const hr = remove_timeline_properties_changed(self, token);

        return switch (hr) {
            windows.S_OK => {},
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }

    pub const AddPlaybackInfoChangedError = error{
        Unexpected,
    };

    pub fn add_PlaybackInfoChanged(
        self: *IGlobalSystemMediaTransportControlsSession,
        handler: *TypedEventHandler(*IGlobalSystemMediaTransportControlsSession, *IPlaybackInfoChangedEventArgs),
    ) AddPlaybackInfoChangedError!EventRegistrationToken {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSession, *TypedEventHandler(*IGlobalSystemMediaTransportControlsSession, *IPlaybackInfoChangedEventArgs), *EventRegistrationToken) callconv(.winapi) HRESULT;
        const add_playback_info_changed: *const FnType = @ptrCast(self.vtable[27]);

        var token: EventRegistrationToken = undefined;

        const hr = add_playback_info_changed(self, handler, &token);
        return switch (hr) {
            windows.S_OK => token,
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }

    pub const AddMediaPropertiesChangedError = error{
        Unexpected,
    };

    pub fn add_MediaPropertiesChanged(
        self: *IGlobalSystemMediaTransportControlsSession,
        handler: *TypedEventHandler(*IGlobalSystemMediaTransportControlsSession, *IMediaPropertiesChangedEventArgs),
    ) AddMediaPropertiesChangedError!EventRegistrationToken {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSession, *TypedEventHandler(*IGlobalSystemMediaTransportControlsSession, *IMediaPropertiesChangedEventArgs), *EventRegistrationToken) callconv(.winapi) HRESULT;
        const add_media_proparties_changed: *const FnType = @ptrCast(self.vtable[29]);

        var token: EventRegistrationToken = undefined;

        const hr = add_media_proparties_changed(self, handler, &token);
        return switch (hr) {
            windows.S_OK => token,
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }
};

// prob add those GlobalSystemMediaTransportControlsSessionManager classes for general use
pub const IGlobalSystemMediaTransportControlsSessionManager = extern struct {
    vtable: [*]const *const anyopaque,

    pub const NAME = "Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager";

    pub const SIGNATURE = "rc(" ++ NAME ++ ";{cace8eac-e86e-504a-ab31-5ff8ff1bce49})";

    pub const UUID = &GUID.parse("{cace8eac-e86e-504a-ab31-5ff8ff1bce49}");

    pub inline fn Release(self: *IGlobalSystemMediaTransportControlsSessionManager) void {
        IUnknown.Release(@ptrCast(self));
    }

    pub const GetCurrentSessionError = error{Unexpected};

    pub fn GetCurrentSession(self: *IGlobalSystemMediaTransportControlsSessionManager) GetCurrentSessionError!?*IGlobalSystemMediaTransportControlsSession {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSessionManager, *?*IGlobalSystemMediaTransportControlsSession) callconv(.winapi) HRESULT;
        const get_current_session: *const FnType = @ptrCast(self.vtable[6]);

        var val: ?*IGlobalSystemMediaTransportControlsSession = undefined;

        const hr = get_current_session(self, &val);
        return switch (hr) {
            windows.S_OK => val,
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }

    pub const AddCurrentSessionChangedError = error{
        Unexpected,
    };

    pub fn add_CurrentSessionChanged(
        self: *IGlobalSystemMediaTransportControlsSessionManager,
        handler: *TypedEventHandler(*IGlobalSystemMediaTransportControlsSessionManager, *ICurrentSessionChangedEventArgs),
    ) AddCurrentSessionChangedError!EventRegistrationToken {
        const FnType = fn (
            *IGlobalSystemMediaTransportControlsSessionManager,
            *TypedEventHandler(*IGlobalSystemMediaTransportControlsSessionManager, *ICurrentSessionChangedEventArgs),
            *EventRegistrationToken,
        ) callconv(.winapi) HRESULT;

        const add_current_session_chnaged: *const FnType = @ptrCast(self.vtable[8]);

        var token: EventRegistrationToken = undefined;

        const hr = add_current_session_chnaged(self, handler, &token);
        return switch (hr) {
            windows.S_OK => token,
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }

    pub const RemoveCurrentSessionChangedError = error{
        Unexpected,
    };

    pub fn remove_CurrentSessionChanged(
        self: *IGlobalSystemMediaTransportControlsSessionManager,
        token: EventRegistrationToken,
    ) RemoveCurrentSessionChangedError!void {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSessionManager, EventRegistrationToken) callconv(.winapi) HRESULT;

        const remove_current_session_chnaged: *const FnType = @ptrCast(self.vtable[9]);
        const hr = remove_current_session_chnaged(self, token);

        return switch (hr) {
            windows.S_OK => {},
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }
};

pub const IGlobalSystemMediaTransportControlsSessionManagerStatics = extern struct {
    vtable: [*]const *const anyopaque,

    pub const NAME = "Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager";
    pub const SIGNATURE = "rc(" ++ NAME ++ ";{2050c4ee-11a0-57de-aed7-c97c70338245})";

    pub const UUID = &GUID.parse("{2050c4ee-11a0-57de-aed7-c97c70338245}");

    pub const RequestAsyncError = error{Unexpected};

    pub inline fn Release(self: *IGlobalSystemMediaTransportControlsSessionManagerStatics) void {
        IUnknown.Release(@ptrCast(self));
    }

    pub fn RequestAsync(
        self: *IGlobalSystemMediaTransportControlsSessionManagerStatics,
    ) RequestAsyncError!*IAsyncOperation(*IGlobalSystemMediaTransportControlsSessionManager) {
        const FnType = fn (*IGlobalSystemMediaTransportControlsSessionManagerStatics, **IAsyncOperation(*IGlobalSystemMediaTransportControlsSessionManager)) callconv(.winapi) HRESULT;
        const request_async: *const FnType = @ptrCast(self.vtable[6]);

        var operation: *IAsyncOperation(*IGlobalSystemMediaTransportControlsSessionManager) = undefined;

        const hr = request_async(self, &operation);
        return switch (hr) {
            windows.S_OK => operation,
            else => windows.unexpectedError(windows.HRESULT_CODE(hr)),
        };
    }
};
