module roblox::rendering::g3d::rbx_ray;

import roblox::rendering::g3d;

struct RbxRay {
    Vector3 origin, direction;
}

fn String RbxRay.to_string(&self, Allocator allocator) {
    bool is_zero = self.origin.is_zero() && self.direction.is_zero();
    return is_zero ? ("Ray.new()").copy(allocator) :
        string::format(
            allocator,
            "Ray.new(%s, %s)",
            self.origin.to_string(allocator),
            self.direction.to_string(allocator)
        );
}
