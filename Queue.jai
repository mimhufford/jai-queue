Queue :: struct (type: Type) {
    data : *void;
    front, back, capacity, count := 0;
    allocator : Allocator;
}

push_front :: (using queue: *Queue, value: queue.type) {
    ensure_capacity(queue);
    front -= 1;
    count += 1;
    if front < 0 then front, back += capacity;
    (data + (front % capacity) * size_of(type)).(*type).* = value;
}

push_back :: (using queue: *Queue, value: queue.type) {
    ensure_capacity(queue);
    (data + (back % capacity) * size_of(type)).(*type).* = value;
    back += 1;
    count += 1;
}

pop_front :: (using queue: *Queue) -> queue.type {
    assert(count > 0);
    result := (data + (front % capacity) * size_of(type)).(*type).*;
    front += 1;
    count -= 1;
    return result;
}

pop_back :: (using queue: *Queue) -> queue.type {
    assert(count > 0);
    back -= 1;
    count -= 1;
    result := (data + (back % capacity) * size_of(type)).(*type).*;
    return result;
}

reset_keeping_memory :: (using queue: *Queue) {
    front, back, count = 0;
}

for_expansion :: (using queue: *Queue, body: Code, flags: For_Flags) #expand {
    `it_index := 0;

    for <=(flags & .REVERSE > 0) index: front..back-1 {
        item := (data + (index % capacity) * size_of(type)).(*type);
        `it := #ifx flags & .POINTER then item else item.*;
        #insert (remove=#assert(false)) body;
        it_index += 1;
    }
}

#scope_file

ensure_capacity :: (using queue: *Queue) {
    bytes := size_of(type);

    if !data {
        // adding the first ever value so need to allocate memory
        capacity = 8;
        data = alloc(capacity * bytes,, allocator);
    } else if count == capacity {
        // the queue is full, double the size and copy values contiguously to the start of the new memory
        wrapped_front := front % capacity;
        new_data := alloc(capacity * 2 * bytes,, allocator);
        memcpy(new_data, data + (wrapped_front * bytes), (capacity - wrapped_front) * bytes);
        memcpy(new_data + (capacity - wrapped_front) * bytes, data, wrapped_front * bytes);
        free(data,, allocator);
        data = new_data;
        front, back, capacity = 0, capacity, capacity * 2;
    }
}

#import "Basic";