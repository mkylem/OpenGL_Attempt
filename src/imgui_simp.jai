/* A file for doing Dear ImGui ops with Simp window 'n' stuff */
// So far this isn't implemented and has been copied from the SDL/OpenGL
// integrated example. All of these procedures will need to be changed
// to interface with the Simp window and still render via the OpenGL hook.
// Unfortunately, there's a memory leak involved with the NewFrame proc.
// Mainly, that's why I swapped to this so I can find exactly what the
// issue is with my own implementation, even though it is guided.

imgui_simp_render_draw_lists :: (draw_data: *ImGui.ImDrawData) #c_call {
    io = ImGui.GetIO();
    fb_width  := io.DisplaySize.x * io.DisplayFramebufferScale.x;
    fb_height := io.DisplaySize.y * io.DisplayFramebufferScale.y;
    if !fb_width || !fb_height return; // No 0-width or 0-height, so avoid when minimized
    draw_data.ScaleClipRects(draw_data, *io.DisplayFramebufferScale);


    glGetIntegerv(GL_ACTIVE_TEXTURE, xx              *last.active_texture);
    glGetIntegerv(GL_CURRENT_PROGRAM, xx             *last.program);    
    glGetIntegerv(GL_TEXTURE_BINDING_2D, xx          *last.texture);    
    glGetIntegerv(GL_SAMPLER_BINDING, xx             *last.sampler);    
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, xx        *last.array_buffer);
    glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING,xx *last.element_array_buffer);
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING, xx        *last.vertex_array);
    glGetIntegerv(GL_POLYGON_MODE, xx                 last.polygon_mode.data);
    glGetIntegerv(GL_VIEWPORT, xx                     last.viewport.data);
    glGetIntegerv(GL_SCISSOR_BOX, xx                  last.scissor_box.data);
    glGetIntegerv(GL_BLEND_SRC_RGB, xx               *last.blend_src_rgb);
    glGetIntegerv(GL_BLEND_DST_RGB, xx               *last.blend_dst_rgb);
    glGetIntegerv(GL_BLEND_SRC_ALPHA, xx             *last.blend_src_alpha);
    glGetIntegerv(GL_BLEND_DST_ALPHA, xx             *last.blend_dst_alpha);
    glGetIntegerv(GL_BLEND_EQUATION_RGB, xx          *last.blend_equation_rgb);
    glGetIntegerv(GL_BLEND_EQUATION_ALPHA, xx        *last.blend_equation_alpha);
    last.enable_blend = glIsEnabled(GL_BLEND);
    last.enable_cull_face = glIsEnabled(GL_CULL_FACE);
    last.enable_depth_test = glIsEnabled(GL_DEPTH_TEST);
    last.enable_scissor_test = glIsEnabled(GL_SCISSOR_TEST);

    // Now setup the ImGui render state
    glActiveTexture(GL_TEXTURE0);
    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_SCISSOR_TEST);
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

    // Setup viewport, orthographic projection matrix
    glViewport(0, 0, xx fb_width, xx fb_height);


    new_context: Context;
    push_context new_context {
        ortho_projection := orthographic_projection_matrix(0, io.DisplaySize.x, io.DisplaySize.y, 0, 0, 1);
        ortho_projection = transpose(ortho_projection);

    }
}

imgui_simp_new_frame :: (window: *window_type) {

}

#scope_file

ImGui :: #import "ImGui";
#import "Basic";
#import "Math";
#import "GL";

#if OS == .WINDOWS {
    #import "Windows";
    window_type :: HWND;
} else #if os == .LINUX {
    #import "X11";
    window_type :: Window;
} else #if OS == .MACOS {
    #import "Objective_C";
    #import "Objective_C/AppKit";
    window_type :: NSWindow;
}

io : *ImGui.IO;

g : struct {
    time: u64;
    mouse_pressed := bool.[false, false, false];
    mouse_wheel:              float = 0.0;
    font_texture:             GLuint = 0;
    shader_handle:            GLuint = 0;
    vert_handle:              GLuint = 0;
    frag_handle:              GLuint = 0;
    attrib_location_tex:      GLint = 0;
    attrib_location_proj_mtx: GLint = 0;
    attrib_location_position: GLint = 0;
    attrib_location_uv:       GLint = 0;
    attrib_location_color:    GLint = 0;
    vbo_handle:               GLuint = 0;
    vao_handle:               GLuint = 0;
    elements_handle:          GLuint = 0;
};

last : struct {
    active_texture:       GLenum;
    program:              GLuint;
    texture:              GLuint;
    sampler:              GLuint;
    array_buffer:         GLuint;
    element_array_buffer: GLuint;
    vertex_array:         GLuint;
    polygon_mode:      [2]GLuint;
    viewport:          [4]GLint;
    scissor_box:       [4]GLint;
    blend_src_rgb:        GLenum;
    blend_dst_rgb:        GLenum;
    blend_src_alpha:      GLenum;
    blend_dst_alpha:      GLenum;
    blend_equation_rgb:   GLenum;
    blend_equation_alpha: GLenum;
    enable_blend:         GLboolean;
    enable_cull_face:     GLboolean;
    enable_depth_test:    GLboolean;
    enable_scissor_test:  GLboolean;
}