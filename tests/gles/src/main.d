module main;

import rtld;

enum VertexAttrib: uint
{
    Vertices = 0,
    Colors = 1
}

// TODO: Linux/X11 support

class Application
{
    HWND hwnd;
    HDC hdc;
    
    OpenGLVersion glVersion;
    GLContext glContext;
    
    WindowState windowState;
    
    bool running = true;
    double timer = 0.0;
    enum double dt = 1.0 / 60.0;
    
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
    
    this() @nogc nothrow
    {
        uint windowWidth = 800;
        uint windowHeight = 600;
        
        hwnd = createWindow(windowWidth, windowHeight, "dcore", &windowState);
        if (hwnd is null)
        {
            printStr("Failed to create window");
            return;
        }
        
        hdc = GetDC(hwnd);
        glVersion = OpenGLES30;
        glContext = loadOpenGL(GLDevice(hdc), glVersion);
        if (!isValidGLContext(glContext))
        {
            printStr("Failed to create OpenGL ES 3.0 context!");
            return;
        }
        
        glViewport(0, 0, windowWidth, windowHeight);
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
        
        projectionMatrix = orthoMatrix(0, windowWidth, windowHeight, 0, -1000, 1000);
        projectionMatrixLoc = glGetUniformLocation(shaderProgram, "projectionMatrix");
        
        auto t = translationMatrix(windowWidth * 0.5, windowHeight * 0.5, 0);
        auto s = scaleMatrix(windowWidth * 0.25f, windowHeight * 0.25f, 1.0f);
        modelViewMatrix = multMatrix(t, s);
        modelViewMatrixLoc = glGetUniformLocation(shaderProgram, "modelViewMatrix");
    }
    
    void onResize(int w, int h) @nogc nothrow
    {
        glViewport(0, 0, w, h);
        
        projectionMatrix = orthoMatrix(0, w, h, 0, -1000, 1000);
        
        auto t = translationMatrix(w * 0.5, h * 0.5, 0);
        auto s = scaleMatrix(w * 0.25f, h * 0.25f, 1.0f);
        modelViewMatrix = multMatrix(t, s);
    }
    
    void run() @nogc nothrow
    {
        timer = getTimeStep();
        
        while(running)
        {
            dispatchMessage(&dispatchWindowsMessage, cast(void*)this);
            
            if (windowState.ss == WindowStateSignal.Resize)
            {
                onResize(windowState.width, windowState.height);
                windowState.ss = WindowStateSignal.None;
            }
            
            double timeStep = getTimeStep();
            timer += timeStep;
            if (timer >= dt)
            {
                timer -= dt;
                glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
                
                glUseProgram(shaderProgram);
                
                glUniformMatrix4fv(projectionMatrixLoc, 1, 0, projectionMatrix.ptr);
                glUniformMatrix4fv(modelViewMatrixLoc, 1, 0, modelViewMatrix.ptr);
                
                glBindVertexArray(vao);
                glDrawElements(GL_TRIANGLES, cast(uint)indices.length, GL_UNSIGNED_SHORT, null);
                glBindVertexArray(0);

                glUseProgram(0);
                
                glFlush();
                SwapBuffers(hdc);
            }
        }
    }
}

void dispatchWindowsMessage(MSG* msg, void* userData) @nogc nothrow
{
    Application app = cast(Application)userData;
    if (app)
    {
        if (msg.message == WM_QUIT)
        {
            app.running = false;
            return;
        }
    }
}

float[16] orthoMatrix(float l, float r, float b, float t, float n, float f) @nogc nothrow
{
    float[16] res;

    float width  = r - l;
    float height = t - b;
    float depth  = f - n;

    res[0] =  2.0 / width;
    res[1] =  0.0;
    res[2] =  0.0;
    res[3] =  0.0;

    res[4] =  0.0;
    res[5] =  2.0 / height;
    res[6] =  0.0;
    res[7] =  0.0;

    res[8] =  0.0;
    res[9] =  0.0;
    res[10]= -2.0 / depth;
    res[11]=  0.0;

    res[12]= -(r + l) / width;
    res[13]= -(t + b) / height;
    res[14]= -(f + n) / depth;
    res[15]=  1.0;

    return res;
}


float[16] translationMatrix(float x, float y, float z) @nogc nothrow
{
    float[16] res;
    
    res[0] = 1.0;
    res[1] = 0.0;
    res[2] = 0.0;
    res[3] = 0.0;
    
    res[4] = 0.0;
    res[5] = 1.0;
    res[6] = 0.0;
    res[7] = 0.0;

    res[8] = 0.0;
    res[9] = 0.0;
    res[10] = 1.0;
    res[11] = 0.0;

    res[12] = x;
    res[13] = y;
    res[14] = z;
    res[15] = 1.0;

    return res;
}

float[16] rotationMatrix(uint rotaxis, float theta) @nogc nothrow
{
    float[16] res;

    float s = sin(theta);
    float c = cos(theta);
    
    res[3] = 0.0;
    res[7] = 0.0;
    res[11] = 0.0;
    res[12] = 0.0;
    res[13] = 0.0;
    res[14] = 0.0;
    res[15] = 1.0;

    switch (rotaxis)
    {
        case 0: // X
            res[0] = 1.0; res[4] = 0.0; res[8] = 0.0;
            res[1] = 0.0; res[5] = c;   res[9] =  s;
            res[2] = 0.0; res[6] = -s;  res[10] =  c;
            break;

        case 1: // Y
            res[0] = c;   res[4] = 0.0; res[8] = -s;
            res[1] = 0.0; res[5] = 1.0; res[9] = 0.0;
            res[2] = s;   res[6] = 0.0; res[10] = c;
            break;

        case 2: // Z
            res[0] = c;   res[4] =  s;  res[8] = 0.0;
            res[1] = -s;  res[5] =  c;  res[9] = 0.0;
            res[2] = 0.0; res[6] = 0.0; res[10] = 1.0;
            break;

        default:
            res[0] = 1.0; res[4] = 0.0; res[8] = 0.0;
            res[1] = 0.0; res[5] = 1.0; res[9] = 0.0;
            res[2] = 0.0; res[6] = 0.0; res[10] = 1.0;
            break;
    }

    return res;
}

float[16] scaleMatrix(float x, float y, float z) @nogc nothrow
{
    float[16] res;
    
    res[0] = x;
    res[1] = 0.0;
    res[2] = 0.0;
    res[3] = 0.0;
    
    res[4] = 0.0;
    res[5] = y;
    res[6] = 0.0;
    res[7] = 0.0;

    res[8] = 0.0;
    res[9] = 0.0;
    res[10] = z;
    res[11] = 0.0;

    res[12] = 0.0;
    res[13] = 0.0;
    res[14] = 0.0;
    res[15] = 1.0;

    return res;
}

float[16] multMatrix(ref float[16] m1, ref float[16] m2) @nogc nothrow
{
    float[16] res;

    res[0] = (m1[0] * m2[0]) + (m1[4] * m2[1]) + (m1[8] * m2[2]) + (m1[12] * m2[3]);
    res[1] = (m1[1] * m2[0]) + (m1[5] * m2[1]) + (m1[9] * m2[2]) + (m1[13] * m2[3]);
    res[2] = (m1[2] * m2[0]) + (m1[6] * m2[1]) + (m1[10] * m2[2]) + (m1[14] * m2[3]);
    res[3] = (m1[3] * m2[0]) + (m1[7] * m2[1]) + (m1[11] * m2[2]) + (m1[15] * m2[3]);

    res[4] = (m1[0] * m2[4]) + (m1[4] * m2[5]) + (m1[8] * m2[6]) + (m1[12] * m2[7]);
    res[5] = (m1[1] * m2[4]) + (m1[5] * m2[5]) + (m1[9] * m2[6]) + (m1[13] * m2[7]);
    res[6] = (m1[2] * m2[4]) + (m1[6] * m2[5]) + (m1[10] * m2[6]) + (m1[14] * m2[7]);
    res[7] = (m1[3] * m2[4]) + (m1[7] * m2[5]) + (m1[11] * m2[6]) + (m1[15] * m2[7]);

    res[8] = (m1[0] * m2[8]) + (m1[4] * m2[9]) + (m1[8] * m2[10]) + (m1[12] * m2[11]);
    res[9] = (m1[1] * m2[8]) + (m1[5] * m2[9]) + (m1[9] * m2[10]) + (m1[13] * m2[11]);
    res[10] = (m1[2] * m2[8]) + (m1[6] * m2[9]) + (m1[10] * m2[10]) + (m1[14] * m2[11]);
    res[11] = (m1[3] * m2[8]) + (m1[7] * m2[9]) + (m1[11] * m2[10]) + (m1[15] * m2[11]);

    res[12] = (m1[0] * m2[12]) + (m1[4] * m2[13]) + (m1[8] * m2[14]) + (m1[12] * m2[15]);
    res[13] = (m1[1] * m2[12]) + (m1[5] * m2[13]) + (m1[9] * m2[14]) + (m1[13] * m2[15]);
    res[14] = (m1[2] * m2[12]) + (m1[6] * m2[13]) + (m1[10] * m2[14]) + (m1[14] * m2[15]);
    res[15] = (m1[3] * m2[12]) + (m1[7] * m2[13]) + (m1[11] * m2[14]) + (m1[15] * m2[15]);

    return res;
}

void main()
{
    Application app = create!Application();
    app.run();
    destroy(app);
}
