module app;

import ui;

TrackingAllocator allocator;

fn int main(String[] args) {
    ui::config = {
        .title = "erspy3",
        .width = 680,
        .height = 400,
        .min_sidebar_width = 150.0f,
        .max_sidebar_width = 300.0f,
    };

    ui::run();

    return 0;
}
