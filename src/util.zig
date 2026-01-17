const std = @import("std");

const Thread = std.Thread;
const Allocator = std.mem.Allocator;

pub fn SynchronizedHashMap(comptime K: type, comptime V: type) type {
    return struct {
        map: Map,
        mu: Thread.Mutex,

        pub const empty: Self = .{ 
            .map = .empty, 
            .mu = .{},
        };

        const Self = @This();
        const Map = std.AutoHashMapUnmanaged(K, V);

        /// Not thread-safe. Caller must ensure exclusivity.
        pub fn deinit(self: *Self, allocator: Allocator) void {
            self.map.deinit(allocator);
            self.* = undefined;
        }

        pub fn get(self: *Self, key: K) ?V {
            self.mu.lock();
            defer self.mu.unlock();

            return self.map.get(key);
        }

        pub fn put(self: *Self, allocator: Allocator, key: K, value: V) Allocator.Error!void {
            self.mu.lock();
            defer self.mu.unlock();

            return self.map.put(allocator, key, value);
        }

        pub fn fetchRemove(self: *Self, key: K) ?Map.KV {
            self.mu.lock();
            defer self.mu.unlock();

            return self.map.fetchRemove(key);
        }

        pub const GetOrPutResult = struct {
            key_ptr: *K,
            value_ptr: *V,
            found_existing: bool,

            mu: *Thread.Mutex,

            pub inline fn done(res: GetOrPutResult) void {
                res.mu.unlock();
            }
        };

        pub fn getOrPut(self: *Self, allocator: Allocator, key: K) Allocator.Error!GetOrPutResult {
            self.mu.lock();
            errdefer self.mu.unlock();

            const res = try self.map.getOrPut(allocator, key);

            return .{
                .key_ptr = res.key_ptr,
                .value_ptr = res.value_ptr,
                .found_existing = res.found_existing,
                .mu = &self.mu,
            };
        }

        pub const ValueIterator = struct {
            it: Map.ValueIterator,
            mu: *Thread.Mutex,

            pub inline fn next(self: *ValueIterator) ?*V {
                return self.it.next();
            }

            pub inline fn done(self: ValueIterator) void {
                self.mu.unlock();
            }

        };

        pub fn valueIterator(self: *Self) ValueIterator {
            self.mu.lock();
            return .{
                .it = self.map.valueIterator(),
                .mu = &self.mu,
            };
        }

    };
}

pub fn SynchronizedArrayList(comptime T: type) type {
    return struct {
        arr_list: ArrayList,
        mu: Thread.Mutex,

        pub const empty: Self = .{
            .arr_list = .empty,
            .mu = .{},
        };

        const Self = @This();
        const ArrayList = std.ArrayList(T);
    };
}
