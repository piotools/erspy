module roblox::rendering::g3d::vector;

struct Vector2 {
    float x, y;
}

struct Vector3 {
    float x, y, z;
}

struct Vector2int16 {
    int x, y;
}

struct Vector3int16 {
    int x, y, z;
}

fn bool Vector2.is_zero(&self) {
    return self.x == 0.0f && self.y == 0.0f;
}

fn bool Vector3.is_zero(&self) {
    return self.x == 0.0f && self.y == 0.0f && self.z == 0.0f;
}

fn bool Vector2int16.is_zero(&self) {
    return self.x == 0 && self.y == 0;
}

fn bool Vector3int16.is_zero(&self) {
    return self.x == 0 && self.y == 0 && self.z == 0;
}

fn String Vector2.to_string(&self, Allocator allocator) {
    return self.is_zero() ? ("Vector2.zero").copy(allocator) :
        string::format(allocator, "Vector2.new(%f, %f)", self.x, self.y);
}

fn String Vector3.to_string(&self, Allocator allocator) {
    return self.is_zero() ? ("Vector3.zero").copy(allocator) :
        string::format(allocator, "Vector3.new(%f, %f, %f)", self.x, self.y, self.z);
}

fn String Vector2int16.to_string(&self, Allocator allocator) {
    return self.is_zero() ? ("Vector2int16.new()").copy(allocator) :
        string::format(allocator, "Vector2int16.new(%d, %d)", self.x, self.y);
}

fn String Vector3int16.to_string(&self, Allocator allocator) {
    return self.is_zero() ? ("Vector3int16.new()").copy(allocator) :
        string::format(allocator, "Vector3int16.new(%d, %d, %d)", self.x, self.y, self.z);
}
