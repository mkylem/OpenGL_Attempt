// To do:
// Clean up all the texture bindings and whatnot, it's really messy.

my_opengl_render :: () {
    // glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
    glClearColor(1.0, 1.0, 1.0, 1.0); // State setting
    glClear(GL_COLOR_BUFFER_BIT);     // State using... huh
                    // Also GL_DEPTH_BUFFER_BIT and GL_STENCIL_BUFFER_BIT
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, render_data[0].texture);
    
    // uniform_loc := glGetUniformLocation(render_data[0].shader_program, "b_in");
    // glUniform1f(uniform_loc, xx (sin(get_time())/2 + 0.5));
    
    glUseProgram(render_data[0].shader_program);
    glBindVertexArray(render_data[0].VAO);
    // glDrawArrays(GL_TRIANGLES, 0, 3);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, cast(*void)0);
    glBindVertexArray(0);
}

glsl_struct :: struct {
    VAO, VBO, EBO,
    vertex_shader, fragment_shader,
    texture,
    shader_program : GLuint;
}
render_data : [..]glsl_struct;

                   // Positions        Colors           Texture position
vertices := float32.[ 0.5, 0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0,
                      0.5,-0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0,
                     -0.5,-0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0,
                     -0.5, 0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0];
indices := u32.[0, 1, 3,
                1, 2, 3];

MY_VERTEX_SHADER := #string END
#version 460 core
layout (location = 0) in vec3 pos;
layout (location = 1) in vec3 acolor;
layout (location = 2) in vec2 atexcoord;

uniform float b_in;

out vec3 color;
out vec2 texcoord;

void main()
{
    gl_Position = vec4(pos, 1.0);
    //color = vec3(acolor.xy, b_in);
    color = acolor;
    texcoord = atexcoord;
}
END

MY_FRAGMENT_SHADER := #string END
#version 460 core
in vec3 color;
in vec2 texcoord;

uniform sampler2D texture1;
uniform sampler2D texture2;

out vec4 fragment_color;

void main()
{
    // fragment_color = vec4(color, 1.0);
    fragment_color = texture(texture1, vec2(texcoord.x, 1-texcoord.y));// * vec4(color, 1.0);
}
END

opengl_setup :: () {
    opengl_maj, opengl_min := gl_get_version();
    print_color("OpenGL version: %.%\n", opengl_maj, opengl_min, color=.CYAN);
    glViewport(0, 0, xx s.window_width, xx s.window_height);
    
    array_add(*render_data, glsl_struct.{});
    
    create_shader(MY_VERTEX_SHADER, .VERTEX_SHADER, *(render_data[0].vertex_shader));
    create_shader(MY_FRAGMENT_SHADER, .FRAGMENT_SHADER, *(render_data[0].fragment_shader));

    my_create_shader_program(*render_data[0]);
    
    
    glGenVertexArrays(1, *(render_data[0].VAO));
    glBindVertexArray(render_data[0].VAO);
    
    glGenBuffers(1, *(render_data[0].VBO));
    glBindBuffer(GL_ARRAY_BUFFER, render_data[0].VBO);
    glBufferData(GL_ARRAY_BUFFER, size_of(float32)*vertices.count, vertices.data, GL_STATIC_DRAW);
    
    glGenBuffers(1, *(render_data[0].EBO));
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, render_data[0].EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(float32)*indices.count, *indices, GL_STATIC_DRAW);
    
    // Position
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8*size_of(float32), xx 0);
    glEnableVertexAttribArray(0);
    // Color
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 8*size_of(float32), xx (3*size_of(float32)));
    glEnableVertexAttribArray(1);
    // Texture position
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8*size_of(float32), xx (6*size_of(float32)));
    glEnableVertexAttribArray(2);
    
    glGenTextures(1, *(render_data[0].texture));
    glBindTexture(GL_TEXTURE_2D, render_data[0].texture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    bmp : Simp.Bitmap;
    // stbi_set_flip_vertically_on_load(xx true);
    result := Simp.bitmap_load(*bmp, "build_dat/depth_of_field_test.jpg");
    if result {
        print("Image load was successful!\n");
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, xx bmp.width, xx bmp.height, 0, GL_RGB, GL_UNSIGNED_BYTE, bmp.data.data);
        glGenerateMipmap(GL_TEXTURE_2D);
    } else return;

    glUseProgram(render_data[0].shader_program);
    
    glUniform1i(glGetUniformLocation(render_data[0].shader_program, "texture1"), 0);
}

shader_t :: enum {
    VERTEX_SHADER :: 0;
    FRAGMENT_SHADER;
}

create_shader :: (shader_text: string, shader_type: shader_t, pointer_to_shader: *u32) -> bool {
    if shader_type == {
        case .VERTEX_SHADER;
        pointer_to_shader.* = glCreateShader(GL_VERTEX_SHADER);
        case .FRAGMENT_SHADER;
        pointer_to_shader.* = glCreateShader(GL_FRAGMENT_SHADER);
        case;
    }
    
    glShaderSource(pointer_to_shader.*, 1, *shader_text.data, null);
    glCompileShader(pointer_to_shader.*);
    success := check_valid_shader(pointer_to_shader.*, tprint("%", shader_type));
    
    return success;
}

check_valid_shader :: (shader: u32, name := "Unsent shader name...") -> bool {
    success : s32;
    glGetShaderiv(shader, GL_COMPILE_STATUS, *success);
    if !success {
        print("% compilation was unsuccessful.\n%", name);
        info_len : s32;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, *info_len);
        info_data := cast(*u8) alloc (info_len,, temp);
        glGetShaderInfoLog(shader, xx info_len, xx *info_len, info_data);
        result : string; result.data = info_data; result.count = info_len;
        print("%\n", result);
        return false;
    }

    print("% compilation was successful.\n", name);
    return true;
}

my_create_shader_program :: (use: *glsl_struct) {
    use.shader_program = glCreateProgram();
    glAttachShader(use.shader_program, use.vertex_shader);
    glAttachShader(use.shader_program, use.fragment_shader);
    glLinkProgram(use.shader_program);
    
    success: s32;
    glGetProgramiv(use.shader_program, GL_LINK_STATUS, *success);
    if !success {
        print("shader_program link failure.\n");
        info_len: s32;
        glGetProgramiv(use.shader_program, GL_INFO_LOG_LENGTH, *info_len);
        info_data := cast(*u8) alloc(info_len,, temp);
        glGetProgramInfoLog(use.shader_program, xx info_len, xx *info_len, info_data);
        result : string; result.data = info_data; result.count = info_len;
        print("%\n", result);
    } else print("shader_program link success.\n");
}

my_glsl_destruct :: () {
    for render_data {
        glDeleteVertexArrays(1, *(it.VAO));
        glDeleteBuffers(1,      *(it.VBO));
        glDeleteBuffers(1,      *(it.EBO));
        glDeleteShader           (it.vertex_shader);
        glDeleteShader           (it.fragment_shader);
        glDeleteProgram          (it.shader_program);
    }
    
    print("Destroyed render_data successfully\n");
}


// Stolen from Simp
my_swap_buffers :: (window: Window_Type, vsync := true) {
    #if OS == .WINDOWS {
    #import "Windows";
        dc := GetDC(window);
        SwapBuffers(dc);
    } else #if OS == .LINUX {
        info := find_window_info(window);
        if (!info) || !info.specific.glx_window {
            log_error("Simp: Attempt to swap_buffers on a previously unseen window!\n");
            return;
        }
        
        glXSwapBuffers(x_global_display, info.specific.glx_window);
    } else #if OS == .MACOS {
        // On macOS, OpenGL buffer swapping is done on the context, not on the view.
        // So we can only swap for the active window. (And you need to swap before switching to another view).
        assert(window == state.current_window_info.window);
        NSOpenGLContext.flushBuffer(the_gl_context);
    } else {
        assert(false);
    }
}

