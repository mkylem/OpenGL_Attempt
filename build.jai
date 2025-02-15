#import "Basic";
#import "Compiler";
#import "Ico_File";

bmp_name :: "build_dat/duck2.bmp";

#run build_exe();
release_build := false;

build_exe :: () {

    w := compiler_create_workspace("Target Program");
    if !w {
        print("Workspace creation failed.\n");
        return;
    }

    target_options := get_build_options(w);
    target_options.output_executable_name = "game";

    if get_build_options().stack_trace == false {
        release_build = true;
        // And disable the console. This was copied from Windows_Resources disable_runtime_console
        target_options.additional_linker_arguments = string.["/SUBSYSTEM:windows", "/ENTRY:mainCRTStartup"];
    }
    set_build_options(target_options, w);

    if release_build {
        compiler_begin_intercept(w);
        add_build_file(tprint("%/src/game.jai", #filepath), w);
        message_loop();
        compiler_end_intercept(w);
    } else add_build_file(tprint("%/src/game.jai", #filepath), w);
    
    set_build_options_dc(.{do_output=false});
}

message_loop :: () {
    while true {
        message := compiler_wait_for_message();
        if message.kind != .PHASE continue;
        phase := cast(*Message_Phase) message;
        if phase.phase != .POST_WRITE_EXECUTABLE continue;

        #if OS == .WINDOWS {
            #import "Windows_Resources";

            if release_build {
                log("Setting icon to '%'\n", bmp_name);

                success := set_icon_by_data(phase.executable_name, create_ico_file_from_bitmap_filename(bmp_name));
                if !success log_error("Failed to set the icon for exe '%' to bmp '%'.\n", phase.executable_name, bmp_name);
            }
        } else {
            log("Setting the icon when OS == % is not yet supported.\n", OS);
        }
        return;
    }
}