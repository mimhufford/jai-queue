Queue :: struct (type: Type) {
    data : *void;
    read, write, capacity, count := 0;
}

enqueue :: (using queue: *Queue, value: queue.type) {
    defer write, count += 1;

    bytes := size_of(type);

    if !data {
        // adding the first ever value so need to allocate memory
        capacity = 8;
        data = alloc(capacity * bytes);
        data.(*type).* = value;
        return;
    }
    
    if write < capacity {
        // there's room at the end of the allocated memory, so copy the value there
        (data + write * bytes).(*type).* = value;
        return;
    }

    wrapped_write := write % capacity;

    if wrapped_write < read {
        // there's a dequeued value at the start which we can overwrite
        (data + wrapped_write * bytes).(*type).* = value;
        return;
    }

    // the queue is full, double the size and copy values contiguously to the start of the new memory
    new_data := alloc(capacity * 2 * bytes);
    memcpy(new_data, data + (read * bytes), (capacity - read) * bytes);
    memcpy(new_data + (capacity - read) * bytes, data, read * bytes);
    free(data);
    data = new_data;
    read, write, capacity = 0, capacity, capacity * 2;
    (data + write * bytes).(*type).* = value;
}

dequeue :: (using queue: *Queue) -> queue.type {
    assert(count > 0);
    result := (data + read * size_of(type)).(*type).*;
    read += 1;
    count -= 1;
    return result;
}

for_expansion :: (using queue: *Queue, body: Code, flags: For_Flags) #expand {
    `it_index := 0;

    for <=(flags & .REVERSE > 0) read..write-1 {
        item := (data + (it % capacity) * size_of(type)).(*type);

        #if flags & .POINTER {
            `it := item;
        } else {
            `it := item.*;
        }

        #insert (remove=#assert(false)) body;

        it_index += 1;
    }
}

#scope_file

#import "Basic";