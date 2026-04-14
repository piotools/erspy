module ui::utils;

import sokol, ig;
import user32;
import lucide;

const char[] INTER_TTF = $embed("../../resources/fonts/Inter_18pt-Regular.ttf");
const char[] LUCIDE_TTF = $embed("../../resources/fonts/" +++ lucide::FONT_ICON_FILE_NAME_LC);

const ImWchar[3] LUCIDE_RANGES = {lucide::ICON_MIN_LC, lucide::ICON_MAX_LC, 0};

fn void init_fonts() {
    ImGuiIO* io = ig::get_ionil();
    ImFontConfig config;

    config.font_data_owned_by_atlas = false;
    config.oversample_h = 2;
    config.oversample_v = 1;
    config.glyph_exclude_ranges = (ImWchar*)&LUCIDE_RANGES;
    config.glyph_max_advance_x = float.max;
    config.rasterizer_multiply = 1.0f;
    config.rasterizer_density = 1.0f;
    config.ellipsis_char = (ImWchar)-1;
    io.fonts.add_font_from_memory_ttf(INTER_TTF.ptr, INTER_TTF.len, 15.0f, &config);

    config.merge_mode = true;
    config.pixel_snap_h = true;
    config.glyph_exclude_ranges = null;
    config.glyph_offset.y = 1.0f;
    io.fonts.add_font_from_memory_ttf(LUCIDE_TTF.ptr, LUCIDE_TTF.len, 14.0f, &config);
}

fn void apply_theme() {
    ImGuiStyle* style = ig::get_style();

    style.frame_padding = {6.0f, 4.0f};
    style.item_spacing = {6.0f, 6.0f};
    style.child_rounding = 4.0f;
    style.frame_rounding = 4.0f;
    style.scrollbar_rounding = 9.0f;
    style.window_border_size = 1.0f;
    style.child_border_size = 1.0f;

    style.colors[(uint)ImGuiCol.TEXT] = {0.85f, 0.85f, 0.85f, 1.00f};
    style.colors[(uint)ImGuiCol.WINDOW_BG] = {0.09f, 0.09f, 0.09f, 1.00f};
    style.colors[(uint)ImGuiCol.BORDER] = {0.18f, 0.18f, 0.18f, 1.00f};
    style.colors[(uint)ImGuiCol.FRAME_BG] = {0.14f, 0.14f, 0.14f, 1.00f};
    style.colors[(uint)ImGuiCol.BUTTON] = {0.18f, 0.18f, 0.18f, 1.00f};
    style.colors[(uint)ImGuiCol.BUTTON_HOVERED] = {0.24f, 0.24f, 0.24f, 1.00f};
    style.colors[(uint)ImGuiCol.BUTTON_ACTIVE] = {0.28f, 0.28f, 0.28f, 1.00f};
    style.colors[(uint)ImGuiCol.HEADER] = {0.22f, 0.32f, 0.45f, 1.00f};
    style.colors[(uint)ImGuiCol.HEADER_HOVERED] = {0.28f, 0.38f, 0.55f, 1.00f};
    style.colors[(uint)ImGuiCol.HEADER_ACTIVE] = {0.35f, 0.45f, 0.65f, 1.00f};
}

fn void unspaced_item() {
    ig::set_cursor_pos_x(ig::get_cursor_pos_x() - ig::get_style().item_spacing.x);
}

fn void align_right_auto(ZString label) {
    ImVec2 size;
    ig::calc_text_size(&size, label, null, false, -1.0f);

    float padding = ig::get_style().frame_padding.x * 2.0f;
    float total_width = size.x + padding;

    ImVec2 avail;
    ig::get_content_region_avail(&avail);
    ig::set_cursor_pos_x(ig::get_cursor_pos_x() + avail.x - total_width);
}

fn void align_center_auto(ZString label) {
    ImVec2 size;
    ig::calc_text_size(&size, label, null, false, -1.0f);

    ImVec2 avail;
    ig::get_content_region_avail(&avail);

    float offset_x = (avail.x - size.x) * 0.5f;
    float offset_y = (avail.y - size.y) * 0.5f;

    if (offset_x > 0.0f && offset_y > 0.0f) {
        ig::set_cursor_pos_x(ig::get_cursor_pos_x() + offset_x);
        ig::set_cursor_pos_y(ig::get_cursor_pos_y() + offset_y);
    }
}

fn void set_topmost(bool enabled) {
    void* hwnd = sapp::win32_get_hwnd();
    if (!hwnd) return;

    void* z_order = enabled ? user32::HWND_TOPMOST : user32::HWND_NOTOPMOST;
    user32::set_window_pos(hwnd, z_order, 0, 0, 0, 0, user32::SWP_NOMOVE | user32::SWP_NOSIZE);
}
