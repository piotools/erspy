module ui;

import logger;

import std::io, std::math;
import std::collections::enummap;
import std::collections::map;
import std::collections::list;
import std::thread;

import sokol, ig;
import nt_ext;
import lucide;
import erspy;
import roblox;

const ImGuiWindowFlags IMGUI_FLAGS =
    ImGuiWindowFlags.NO_TITLE_BAR |
    ImGuiWindowFlags.NO_RESIZE |
    ImGuiWindowFlags.NO_MOVE |
    ImGuiWindowFlags.NO_COLLAPSE |
    ImGuiWindowFlags.NO_BRING_TO_FRONT_ON_FOCUS;

const uint MAX_REMOTES @private = 500;
const uint MAX_PACKETS @private = 100;

struct UiConfiguration {
    String title;
    int width, height;
    float min_sidebar_width, max_sidebar_width;
}

struct UiState {
    SgPassAction pass_action;
    bool is_active, top_most;
    char[256] search_buf;
    float sidebar_width;

    HashMap{uptr, RemoteEntry*} logs;
    List{uptr} order;

    uptr remote;
    isz packet_idx;

    double cleanup_timer;
}

EnumMap{EventType, ImVec4} event_colors;

UiConfiguration config;
UiState state = {
    .pass_action.colors[0] = {
        .load_action = CLEAR,
        .clear_value = {0.1f, 0.1f, 0.1f, 1.0f},
    },

    .top_most = true,
    .sidebar_width = 250.0f,
    .packet_idx = -1,
};

TrackingAllocator allocator;
RemoteSpy spy;
Thread spy_thread;
Mutex mutex;

fn void run() {
    sapp::run(&&(SappDesc) {
        .init_cb = &init,
        .frame_cb = &render,
        .cleanup_cb = &cleanup,
        .event_cb = &handle_event,
        .width = config.width,
        .height = config.height,
        .window_title = (ZString)config.title,
        .logger.func = &slog::func,
    });
}

fn void init() @private {
    sg::setup(&&(SgDesc) {
        .environment = sglue::environment(),
        .logger.func = &slog::func,
    });

    simgui::setup(&&(SimguiDesc) {
        .no_default_font = true
    });

    utils::init_fonts();
    utils::apply_theme();
    utils::set_topmost(state.top_most);

    allocator.init(mem);
    state.logs.init(&allocator);
    state.order.init(&allocator);
    mutex.init()!!;
}

fn void cleanup() @private {
    mutex.destroy()!!;
    state.order.free();
    state.logs.free();

    (void)spy.deinit();
    allocator.free();

    simgui::shutdown();
    sg::shutdown();
}

fn void handle_event(SappEvent* ev) @private {
    simgui::handle_event(ev);
}

fn void render() @private {
    double delta = sapp::frame_duration();

    simgui::new_frame(&&(SimguiFrameDesc) {
        .width = sapp::width(),
        .height = sapp::height(),
        .delta_time = delta,
    });

    ig::set_next_window_pos({}, ALWAYS);
    ig::set_next_window_size({sapp::widthf(), sapp::heightf()}, ALWAYS);

    if (ig::begin("##window", null, IMGUI_FLAGS)) {
        state.cleanup_timer += delta;
        if (state.is_active && state.cleanup_timer >= 5.0) {
            clean_remotes()!!;
            state.cleanup_timer = 0.0;
        }

        render_toolbar();
        render_sidebar();

        ig::same_line();
        utils::unspaced_item();
        render_content_panel();

        ig::end();
    }

    sg::begin_pass(&&(SgPass) {
        .action = state.pass_action,
        .swapchain = sglue::swapchain()
    });

    simgui::render();

    sg::end_pass();
    sg::commit();
}

fn void render_toolbar() @private {
    bool is_attached = spy.is_running;
    if (!is_attached) {
        state.is_active = false;
    }

    ig::begin_disabled(is_attached);
    if (ig::button(is_attached ? lucide::ICON_LC_SYRINGE +++ " Attached" : lucide::ICON_LC_SYRINGE +++ " Attach")) {
        if (catch err = attach_spy()) {
            logger::warn("Failed to attach: %s", err);
        }
        state.is_active = spy.is_running;
    }
    ig::end_disabled();

    ig::same_line();
    ig::begin_disabled(!is_attached);
    if (ig::button(state.is_active ? lucide::ICON_LC_PAUSE +++ " Pause" : lucide::ICON_LC_PLAY +++ " Play")) {
        state.is_active = !state.is_active;
        spy.engine.toggle_hooks(state.is_active)!!;
    }
    ig::end_disabled();

    ig::same_line();
    if (ig::button(lucide::ICON_LC_TRASH +++ " Clear")) {
        clear_logs()!!;
    }

    ZString label = state.top_most ? lucide::ICON_LC_PIN +++ " TopMost: On" : lucide::ICON_LC_PIN_OFF +++ " TopMost: Off";

    ig::same_line();
    utils::align_right_auto(label);

    if (ig::button(label)) {
        state.top_most = !state.top_most;
        utils::set_topmost(state.top_most);
    }
}

fn void render_sidebar() @private {
    ig::begin_child_str("##sidebar", {state.sidebar_width, 0}, 1);

    ig::push_item_width(-1.0f);
    ig::input_text_with_hint("##search", lucide::ICON_LC_SEARCH +++ " Search remotes...", (ZString)&state.search_buf, state.search_buf.len, 0);
    ig::pop_item_width();

    ig::separator();
    render_remotes_list();

    ig::end_child();

    ig::push_style_color_vec4(BUTTON, {});
    ig::push_style_color_vec4(BUTTON_ACTIVE, {0.2f, 0.2f, 0.2f, 0.5f});

    ig::same_line();
    utils::unspaced_item();
    ig::button("##splitter", {4.0f, -1.0f});

    ig::pop_style_color(2);

    if (ig::is_item_active()) {
        state.sidebar_width = math::clamp(
            state.sidebar_width + ig::get_ionil().mouse_delta.x,
            config.min_sidebar_width,
            config.max_sidebar_width
        );
    }

    if (ig::is_item_hovered(0)) {
        ig::set_mouse_cursor(RESIZE_EW);
    }
}

fn void render_remotes_list() @private {
    ig::begin_child_str("##remotes_list", {-1.0f, -1.0f});
    ig::push_style_var_vec2(FRAME_PADDING, {4.0f, 3.0f});

    defer {
        ig::pop_style_var();
        ig::end_child();
    };

    mutex.lock()!!;
    defer mutex.unlock()!!;

    if (state.order.len() == 0) {
        ZString label = "No remotes to display.";
        utils::align_center_auto(label);
        ig::text_disabled(label);
        return;
    }

    foreach (instance : state.order) render_remote_entry(instance);
}

fn void render_remote_entry(uptr remote) @private {
    RemoteEntry* entry = state.logs[remote]!!;
    usz count = entry.history.len();

    bool is_open = ig::tree_node_ex_ptr(entry, SPAN_FULL_WIDTH, "");
    if (ig::is_item_toggled_open() && is_open && count == 1) {
        state.remote = remote;
        state.packet_idx = 0;
    }

    ig::same_line();
    ig::text_colored(event_colors[entry.type], lucide::ICON_LC_PLUG_ZAP);
    ig::same_line();
    ig::text("(%d) %.*s", count, entry.name.len, (ZString)entry.name);

    if (!is_open) return;
    defer ig::tree_pop();

    usz start_index = math::max((isz)0, (isz)(count - MAX_PACKETS));
    for (usz i = start_index; i < count; i++) render_packet_selectable(remote, i);
}

fn void render_packet_selectable(uptr remote, usz i) @private {
    ig::push_idint((uint)i);
    defer ig::pop_id();

    bool is_selected = (state.remote == remote && state.packet_idx == (isz)i);
    if (ig::selectable_bool("##selectable", is_selected, SPAN_ALL_COLUMNS)) {
        state.remote = remote;
        state.packet_idx = (isz)i;
    }

    ig::same_line();
    ig::text("%s Packet #%d", lucide::ICON_LC_SCREEN_SHARE, i + 1);
}

fn void render_content_panel() @private {
    ig::begin_child_str("##content", {-1.0f, -1.0f}, 1);

    RemoteEntry* entry = state.logs.get(state.remote) ?? null;
    if (!entry || state.packet_idx == -1) {
        ZString label = "Select a packet to view details";
        utils::align_center_auto(label);
        ig::text_disabled(label);
        ig::end_child();
        return;
    }

    CapturedPacket* captured = &entry.history[(usz)state.packet_idx];

    ig::text_colored({0.4f, 0.7f, 1.0f, 1.0f}, lucide::ICON_LC_INFO +++ " Remote Info");
    ig::separator();
    ig::text("Name: %.*s", entry.name.len, (ZString)entry.name);
    ig::text("Path: %.*s", entry.path.len, (ZString)entry.path);

    ig::spacing();
    ig::text_colored({0.4f, 0.7f, 1.0f, 1.0f}, lucide::ICON_LC_LIST +++ " Arguments");

    ImGuiTableFlags flags =
        ImGuiTableFlags.ROW_BG |
        ImGuiTableFlags.SCROLL_Y |
        ImGuiTableFlags.BORDERS;

    if (ig::begin_table("##args", 2, flags, {-1.0f, -ig::get_frame_height_with_spacing()})) {
        ig::table_setup_column("Value", WIDTH_STRETCH);
        ig::table_setup_column("Type", WIDTH_FIXED, 100.0f);

        ig::table_next_row();
        ig::table_next_column();
        ig::text_disabled("Value");

        ig::table_next_column();
        ig::text_disabled("Type");

        foreach (arg : captured.args) {
            ig::table_next_row();
            ig::table_next_column();
            ig::text((ZString)arg.display);

            ig::table_next_column();
            ig::text_disabled("%s", arg.type.nameof);
        }
        ig::end_table();
    }

    if (ig::button("Repeat call")) spy.engine.recall_packet(&captured.raw)!!;

    ig::end_child();
}

fn void? clear_logs() @private {
    mutex.lock()!;
    defer mutex.unlock()!!;

    state.logs.@each(; remote, entry) {
        entry.free(&allocator);
        allocator::free(&allocator, entry);
    };

    state.logs.clear();
    state.order.clear();

    state.remote = 0;
    state.packet_idx = -1;
}

fn void? clean_remotes() @private {
    if (state.logs.len() >= MAX_REMOTES) {
        uptr key = state.order.pop_first()!;
        RemoteEntry* value = state.logs[key]!;

        value.free(&allocator);
        allocator::free(&allocator, value);

        state.logs.remove(key);
    }

    foreach (entry : state.logs.iter()) {
        InstanceEx instance;
        bool is_invalid = false;

        if (catch instance.init(&allocator, spy.client.memory, entry.value.instance)) {
            is_invalid = true;
        }

        if (catch instance.get_parent()) {
            is_invalid = true;
        }

        if (!is_invalid) continue;

        entry.value.free(&allocator);
        allocator::free(&allocator, entry.value);

        state.logs.remove(entry.key);
        state.order.remove_item(entry.key);
    };
}

fn void? attach_spy() @private {
    uint roblox_pid = process::find_process_id("RobloxPlayerBeta.exe")!;
    spy.init(&allocator, roblox_pid)!;
    spy.on_event = &packet_handler;

    spy_thread.create(fn (void* arg) {
        ((RemoteSpy*)arg).listen()!!;
        return 0;
    }, &spy)!!;

    spy_thread.detach();
}

fn void packet_handler(RemoteSpy* spy, Packet* packet) @private {
    mutex.lock()!!;
    defer mutex.unlock()!!;

    uptr remote = (uptr)packet.remote;
    RemoteEntry* entry = state.logs.get(remote) ?? null;

    if (!entry) {
        clean_remotes()!!;
        entry = utils::alloc_remote_entry(spy, packet.type, remote)!!;
        state.logs[remote] = entry;
        state.order.push(remote);
    }

    CapturedPacket captured;
    captured.raw = *packet;
    captured.args.init(&allocator);

    TupleEx? temp_args = packet.get_args(&allocator, spy.client.memory);
    if (catch temp_args) {
        captured.encoded_args = ("{}").copy(&allocator);
        entry.history.push(captured);
        return;
    }
    defer temp_args.free();

    foreach (&variant : temp_args) {
        VariantEx ex;
        ex.init(temp_args.memory, temp_args.get_address(variant))!!;

        TTypeId id;
        String fmt = ex.to_string(&allocator, &id) ?? "nil".copy(&allocator);

        captured.args.push({
            .type = id,
            .data = *variant,
            .display = fmt
        });
    }

    entry.history.push(captured);
}

fn void colors_init() @local @init {
    event_colors[RELIABLE] = {1.0f, 0.85f, 0.1f, 1.0f};
    event_colors[UNRELIABLE] = {1.0f, 0.55f, 0.0f, 1.0f};
    event_colors[FUNCTION] = {0.65f, 0.55f, 1.0f, 1.0f};
}
