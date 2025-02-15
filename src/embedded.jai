/* Not embedded as in MCU or firmware, but things that are embedded in
    the .exe during compile-time */

#import "Compiler";
#import "File";
embedded_font :: #run add_global_data(get_font(), .READ_ONLY);

get_font :: () -> [] u8 {
    filename := tprint("%../build_dat/RulerGold.ttf", #filepath);
    result, success := read_entire_file(filename);

    if !success compiler_report(tprint("Unable to read file '%'!\n", filename));
    return xx result;
}