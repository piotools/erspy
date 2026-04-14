module roblox::rendering::g3d::rect2d;

import roblox::rendering::g3d;

struct Rect2D {
    Vector2 min, max;
}

fn String Rect2D.to_string(&self, Allocator allocator) {
    bool is_zero = self.min.is_zero() && self.max.is_zero();
    return is_zero ? ("Rect.new()").copy(allocator) :
        string::format(
            allocator,
            "Rect.new(%s, %s)",
            self.min.to_string(allocator),
            self.max.to_string(allocator)
        );
}
