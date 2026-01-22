Queue :: struct (type: Type) {
    data : *void;
    read, write, capacity, count := 0;
    allocator : Allocator;
}

push_back :: (using queue: *Queue, value: queue.type) {
    bytes := size_of(type);

    if !data {
        // adding the first ever value so need to allocate memory
        capacity = 8;
        data = alloc(capacity * bytes,, allocator);
    } else if count == capacity {
        // the queue is full, double the size and copy values contiguously to the start of the new memory
        wrapped_read := read % capacity;
        new_data := alloc(capacity * 2 * bytes,, allocator);
        memcpy(new_data, data + (wrapped_read * bytes), (capacity - wrapped_read) * bytes);
        memcpy(new_data + (capacity - wrapped_read) * bytes, data, wrapped_read * bytes);
        free(data,, allocator);
        data = new_data;
        read, write, capacity = 0, capacity, capacity * 2;
    }

    (data + (write % capacity) * bytes).(*type).* = value;
    write, count += 1;
}

pop_front :: (using queue: *Queue) -> queue.type {
    assert(count > 0);
    result := (data + (read % capacity) * size_of(type)).(*type).*;
    read += 1;
    count -= 1;
    return result;
}

pop_back :: (using queue: *Queue) -> queue.type {
    assert(count > 0);
    write -= 1;
    count -= 1;
    result := (data + (write % capacity) * size_of(type)).(*type).*;
    return result;
}

reset_keeping_memory :: (using queue: *Queue) {
    read, write, count = 0;
}

for_expansion :: (using queue: *Queue, body: Code, flags: For_Flags) #expand {
    `it_index := 0;

    for <=(flags & .REVERSE > 0) index: read..write-1 {
        item := (data + (index % capacity) * size_of(type)).(*type);
        `it := #ifx flags & .POINTER then item else item.*;
        #insert (remove=#assert(false)) body;
        it_index += 1;
    }
}

#scope_file

#import "Basic";