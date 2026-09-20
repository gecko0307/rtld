module main;

import rtld;
import transform;

enum VertexAttrib: uint
{
    Vertices = 0,
    Colors = 1
}

class Application: SystemWindow
{
    float[] vertices = [
        0.0, -1.0, 0.0,
        -1.0, 1.0, 0.0,
        1.0, 1.0, 0.0
    ];

    float[] colors = [
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 0.0, 1.0
    ];

    ushort[] indices = [
        0,  1,  2
    ];
    
    uint vbo;
    uint cbo;
    uint eao;
    uint vao;

    uint vs;
    uint fs;

    string vertexShader =
    "#version 300 es
    precision highp float;

    layout (location = 0) in vec3 va_Vertex;
    layout (location = 1) in vec3 va_Color;

    out vec3 color;

    uniform mat4 projectionMatrix;
    uniform mat4 modelViewMatrix;

    void main(void)
    {
        vec4 pos = projectionMatrix * modelViewMatrix * vec4(va_Vertex, 1.0);
        color = va_Color;
        gl_Position = pos;
    }
    ";

    string fragmentShader =
    "#version 300 es
    precision highp float;

    in vec3 color;

    out vec4 frag_color;

    void main(void)
    {
        frag_color = vec4(color, 1.0);
    }
    ";
    
    uint shaderProgram;

    float[16] projectionMatrix;
    uint projectionMatrixLoc;

    float[16] modelViewMatrix;
    uint modelViewMatrixLoc;
    
    this()
    {
        SystemWindowCreationSettings windowSettings = {
            width: 800,
            height: 600,
            center: true,
            title: "RTLD"w.ptr
        };
        super(&windowSettings);
        
        if (!createGLContext(OpenGLES30))
        {
            printf("Failed to create OpenGL ES 3.0 context!\n");
            running = false;
            exit(1);
        }
        
        printf("GL_VENDOR: %s\n", glGetString(GL_VENDOR));
        printf("GL_RENDERER: %s\n", glGetString(GL_RENDERER));
        printf("GL_VERSION: %s\n", glGetString(GL_VERSION));
        
        initGL();
    }
    
    void initGL()
    {
        glViewport(0, 0, width, height);
        glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
        glClearDepthf(1.0f);
        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LESS);
        glDisable(GL_CULL_FACE);
        
        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, cast(ubyte*)vertices.ptr, GL_STATIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        
        glGenBuffers(1, &cbo);
        glBindBuffer(GL_ARRAY_BUFFER, cbo);
        glBufferData(GL_ARRAY_BUFFER, colors.length * float.sizeof, cast(ubyte*)colors.ptr, GL_STATIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);

        glGenBuffers(1, &eao);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, eao);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * ushort.sizeof, cast(ubyte*)indices.ptr, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        
        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, eao);
        
        glEnableVertexAttribArray(VertexAttrib.Vertices);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glVertexAttribPointer(VertexAttrib.Vertices, 3, GL_FLOAT, false, 0, null);
        
        glEnableVertexAttribArray(VertexAttrib.Colors);
        glBindBuffer(GL_ARRAY_BUFFER, cbo);
        glVertexAttribPointer(VertexAttrib.Colors, 3, GL_FLOAT, false, 0, null);
        
        glBindVertexArray(0);
        
        vs = glCreateShader(GL_VERTEX_SHADER);
        const(char)* vsSrc = vertexShader.ptr;
        GLint vsLen = cast(GLint)vertexShader.length;
        glShaderSource(vs, 1, &vsSrc, &vsLen);
        glCompileShader(vs);
        
        fs = glCreateShader(GL_FRAGMENT_SHADER);
        const(char)* fsSrc = fragmentShader.ptr;
        GLint fsLen = cast(GLint)fragmentShader.length;
        glShaderSource(fs, 1, &fsSrc, &fsLen);
        glCompileShader(fs);
        
        shaderProgram = glCreateProgram();
        
        glAttachShader(shaderProgram, vs);
        glAttachShader(shaderProgram, fs);
        
        glLinkProgram(shaderProgram);
        
        projectionMatrix = orthoMatrix(0, width, height, 0, -1000, 1000);
        projectionMatrixLoc = glGetUniformLocation(shaderProgram, "projectionMatrix");
        
        auto t = translationMatrix(width * 0.5, height * 0.5, 0);
        auto s = scaleMatrix(width * 0.25f, height * 0.25f, 1.0f);
        modelViewMatrix = multMatrix(t, s);
        modelViewMatrixLoc = glGetUniformLocation(shaderProgram, "modelViewMatrix");
    }
    
    override void onResize(uint w, uint h)
    {
        glViewport(0, 0, w, h);
        
        projectionMatrix = orthoMatrix(0, w, h, 0, -1000, 1000);
        
        auto t = translationMatrix(w * 0.5, h * 0.5, 0);
        auto s = scaleMatrix(w * 0.25f, h * 0.25f, 1.0f);
        modelViewMatrix = multMatrix(t, s);
        
        render();
    }
    
    override void onQuit()
    {
        printf("Quit\n");
        
        glDeleteProgram(shaderProgram);
        glDeleteShader(vs);
        glDeleteShader(fs);
        
        uint[3] buffers = [vbo, cbo, eao];
        glDeleteBuffers(3, buffers.ptr);
        glDeleteVertexArrays(1, &vao);
    }
    
    override void onUpdate(double dt)
    {
        render();
    }
    
    void render()
    {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glUseProgram(shaderProgram);
        
        glUniformMatrix4fv(projectionMatrixLoc, 1, 0, projectionMatrix.ptr);
        glUniformMatrix4fv(modelViewMatrixLoc, 1, 0, modelViewMatrix.ptr);
        
        glBindVertexArray(vao);
        glDrawElements(GL_TRIANGLES, cast(uint)indices.length, GL_UNSIGNED_SHORT, null);
        glBindVertexArray(0);

        glUseProgram(0);
        
        glFlush();
        swapBuffers();
    }
}

void main()
{
    version(linux)
    {
        setenv("LIBGL_DRI3_ENABLE", "1", 1);
        //setenv("LIBGL_ALWAYS_SOFTWARE", "0", 1);
        //setenv("GALLIUM_DRIVER", "", 1); 
        setenv("EGL_LOG_LEVEL", "debug", 1);
        setenv("LIBGL_DEBUG", "verbose", 1);
    }
    
    Application app = create!Application();
    app.run();
    destroy(app);
}
