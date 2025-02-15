/* --- Audio --- */
// #import "Sound_Player";
// #import "Wav_File";
// #import "stb_vorbis";

/* --- Video --- */
#import "Window_Creation";
#import "GL"(DUMP_GL_ERRORS=true, ENABLE_ALL_EXTENSIONS=true);
// ImGui   :: #import "ImGui";
Simp    :: #import "Simp";

/* --- Data-on-disc --- */
#import "File";
#import "System";

/* --- General --- */
#import "Basic"()(MEMORY_DEBUGGER=true);
#import "Print_Color";
#import "Input";
#import "Math";
#import "String";

#load "my_opengl.jai";
/* -- End of build-time data -- */

settings :: struct {
    using video : struct {
        desired_aspect_ratio : float64 = 16/9;
        union {
            horizontal_resolution : s32 = 1920;
            window_width          : s32;
        }
        union {
            vertical_resolution : s32 = 1080;
            window_height       : s32;
        }
        game_x : s32 = 1920;
        game_y : s32 = 1080;
        
        desired_frame_rate : s32 = 500;
        desired_delta_time := (1/500);
    };
    
    using audio : struct {
        volume := 100.0;
        sfx    := 100.0;
        music  := 100.0;
        voice  := 100.0;
    };
    
    /*  So, here's normally where I'd have the controller input/conversions.
        I think that the best way to go about user mappings is to allow them
        to set multiple keys as a given inupt (some for the same action).
        There are many ways to do this, since each input is necessarily 
        different depending on your mentality which is:
        1. Remap keys with regards to a controller
        2. Remap keys with regards to the exact action they do.
                            The one I want to do is TBD.
                                                            -mkylem 11-25-23 */
};

s : settings;

WAV :: "wav";

key_left  : u32;
key_right : u32;
key_up    : u32;
key_down  : u32;

should_ignore_input := false;
should_quit_game    := false;

is_fullscreen       := false;
window: Window_Type;
window_info: Saved_Window_Info;
// my_font:    *Simp.Dynamic_Font;

should_output_metrics := false;
current_dt: float = 0;
last_time:  float64;

GAME_STATE :: enum u8 {
    SHOULD_QUIT  :: 0;
    OPENING_MENU :: 1;
    IN_GAME      :: 2;
    GAME_MENU    :: 3;
    IN_EDITOR    :: 4;
}
game_state := GAME_STATE.OPENING_MENU;

main :: () {
    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        Windows.SetProcessDPIAware();
    } else if OS == .MACOS {
        
    } else if OS == .LINUX {
        
    }

    path := path_strip_filename(get_path_of_running_executable());
    data_folder := join(path, "dat");
    image_folder := join(path, "img");

    s.window_width  = 1920;
    s.window_height = 1080;

    last_time = seconds_since_init();

    window = create_window(window_name="Enceladus", width = s.window_width, height = s.window_height);
    gl_create_context(window, 4, 6);
    gl_load(*gl);
    gl_enable_debug_output(break_on_error = true);
    //Simp.set_render_target(window);

    opengl_setup();

    while game_state {
        reset_temporary_storage(); // @Learn: I know this is a how_to, probably the one about temporary storage!
        update_window_events();

        current_dt = cast(float) (seconds_since_init() - last_time);
        last_time += current_dt;

        // Resize game render area
        for get_window_resizes() {
            //Simp.update_window(it.window);
            if it.window == window {
                should_reinit := ((it.width != s.window_width) || (it.height != s.window_height));

                if should_reinit {
                    s.window_width  = it.width;
                    s.window_height = it.height;
                    window_resolution_changed();
                }
            }
        }

        for event : events_this_frame {
            if event.type == .QUIT {
                game_state = .SHOULD_QUIT;
                break;
            } else if event.type == .KEYBOARD {
                process_game_inputs(event);
            }
        }

        dx: Vector2;

        if key_up     dx.y += 1;
        if key_down   dx.y -= 1;
        if key_right  dx.x += 1;
        if key_left   dx.x -= 1;
        if length(dx) > 1 { dx = unit_vector(dx); } // Normalize diagonal velocities

        my_opengl_render();
        my_swap_buffers(window, vsync=false);
        //memory_visualizer_per_frame_update();
    }
    my_glsl_destruct();    
}

window_resolution_changed :: () {
    // Other window-resolution change stuffs
    glViewport(0, 0, xx s.window_width, xx s.window_height);
}

process_game_inputs :: (event: Event) {
    if event.key_pressed then if event.key_code == {
        case .F4;     #through;
        case .ESCAPE; game_state = .SHOULD_QUIT;
        case .F11; 
            is_fullscreen ^= true;
            toggle_fullscreen(window, is_fullscreen, *window_info);
        case #char "`";
            should_output_metrics ^= true;
        case;
    }
    
    key := event.key_code;

    if (key == .ARROW_LEFT  || key == #char "A")   key_left  = event.key_pressed;
    if (key == .ARROW_RIGHT || key == #char "D")   key_right = event.key_pressed;
    if (key == .ARROW_UP    || key == #char "W")   key_up    = event.key_pressed;
    if (key == .ARROW_DOWN  || key == #char "S")   key_down  = event.key_pressed;
}