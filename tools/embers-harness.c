// Developer tool: runs the ember fragment shader on Mesa's software GL (headless EGL) and writes the frame as a
// PAM image (premultiplied RGBA), so the shader can be looked at without a GPU or a compositor. Use
// tools/preview-embers.sh, which builds and calls this.
//
//   usage: embers-harness shader.frag W H time seed intensity density out.pam
//   shader.frag is the GLES variant: qsb -x "glsl,100 es" -o shader.frag embers.frag.qsb
//   FRAMES=N also times N further draws (ms per draw on stderr; llvmpipe, so not GPU timings).
//
// This tests the shader, not the Qt integration. qt_TexCoord0 has y = 0 at the top, as in Qt.
#include <EGL/egl.h>
#include <GLES3/gl3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static char *slurp(const char *p) {
  FILE *f = fopen(p, "rb"); if (!f) { perror(p); exit(1); }
  fseek(f, 0, SEEK_END); long n = ftell(f); rewind(f);
  char *b = malloc(n + 1); if (fread(b, 1, n, f) != (size_t)n) { perror(p); exit(1); }
  b[n] = 0; fclose(f); return b;
}

static GLuint compile(GLenum type, const char *src) {
  GLuint s = glCreateShader(type); glShaderSource(s, 1, &src, NULL); glCompileShader(s);
  GLint ok; glGetShaderiv(s, GL_COMPILE_STATUS, &ok);
  if (!ok) { char log[4096]; glGetShaderInfoLog(s, sizeof log, NULL, log); fprintf(stderr, "shader compile failed:\n%s\n", log); exit(2); }
  return s;
}

int main(int argc, char **argv) {
  if (argc < 9) { fprintf(stderr, "usage: %s shader.frag W H time seed intensity density out.pam\n", argv[0]); return 1; }
  int W = atoi(argv[2]), H = atoi(argv[3]);
  float t = atof(argv[4]), seed = atof(argv[5]), inten = atof(argv[6]), dens = atof(argv[7]);

  EGLDisplay dpy = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  EGLint maj, min; if (!eglInitialize(dpy, &maj, &min)) { fprintf(stderr, "eglInitialize failed 0x%x\n", eglGetError()); return 3; }
  eglBindAPI(EGL_OPENGL_ES_API);
  EGLint ca[] = { EGL_SURFACE_TYPE, EGL_PBUFFER_BIT, EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT, EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8, EGL_NONE };
  EGLConfig cfg; EGLint n; if (!eglChooseConfig(dpy, ca, &cfg, 1, &n) || n < 1) { fprintf(stderr, "no config 0x%x\n", eglGetError()); return 4; }
  EGLint pa[] = { EGL_WIDTH, 16, EGL_HEIGHT, 16, EGL_NONE }; EGLSurface surf = eglCreatePbufferSurface(dpy, cfg, pa);
  EGLint xa[] = { EGL_CONTEXT_CLIENT_VERSION, 3, EGL_NONE }; EGLContext ctx = eglCreateContext(dpy, cfg, EGL_NO_CONTEXT, xa);
  if (!eglMakeCurrent(dpy, surf, surf, ctx)) { fprintf(stderr, "makecurrent failed 0x%x\n", eglGetError()); return 5; }
  fprintf(stderr, "GL: %s | %s\n", glGetString(GL_RENDERER), glGetString(GL_VERSION));

  const char *vs = "attribute vec2 pos; varying vec2 qt_TexCoord0; void main(){ qt_TexCoord0 = vec2(pos.x*0.5+0.5, 0.5-pos.y*0.5); gl_Position = vec4(pos,0.0,1.0); }";
  GLuint prog = glCreateProgram();
  glAttachShader(prog, compile(GL_VERTEX_SHADER, vs)); glAttachShader(prog, compile(GL_FRAGMENT_SHADER, slurp(argv[1])));
  glBindAttribLocation(prog, 0, "pos"); glLinkProgram(prog);
  GLint ok; glGetProgramiv(prog, GL_LINK_STATUS, &ok);
  if (!ok) { char log[4096]; glGetProgramInfoLog(prog, sizeof log, NULL, log); fprintf(stderr, "link failed:\n%s\n", log); return 6; }
  glUseProgram(prog);
  float I4[16] = {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1};
  glUniformMatrix4fv(glGetUniformLocation(prog, "ubuf.qt_Matrix"), 1, GL_FALSE, I4);
  glUniform1f(glGetUniformLocation(prog, "ubuf.qt_Opacity"), 1.f);
  glUniform1f(glGetUniformLocation(prog, "ubuf.time"), t);
  glUniform1f(glGetUniformLocation(prog, "ubuf.intensity"), inten);
  glUniform1f(glGetUniformLocation(prog, "ubuf.density"), dens);
  glUniform1f(glGetUniformLocation(prog, "ubuf.seed"), seed);
  glUniform2f(glGetUniformLocation(prog, "ubuf.resolution"), (float)W, (float)H);

  GLuint fbo, tex; glGenTextures(1, &tex); glBindTexture(GL_TEXTURE_2D, tex);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, W, H, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
  glGenFramebuffers(1, &fbo); glBindFramebuffer(GL_FRAMEBUFFER, fbo);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);
  glViewport(0, 0, W, H); glClearColor(0, 0, 0, 0); glClear(GL_COLOR_BUFFER_BIT);
  float quad[] = { -1,-1, 1,-1, -1,1, 1,1 }; glEnableVertexAttribArray(0); glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, quad);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4); glFinish();
  if (getenv("FRAMES")) {
    int N = atoi(getenv("FRAMES")); struct timespec a, b; clock_gettime(CLOCK_MONOTONIC, &a);
    for (int i = 0; i < N; i++) { glDrawArrays(GL_TRIANGLE_STRIP, 0, 4); glFinish(); }
    clock_gettime(CLOCK_MONOTONIC, &b);
    fprintf(stderr, "DRAW_MS %.1f\n", ((b.tv_sec - a.tv_sec) * 1e3 + (b.tv_nsec - a.tv_nsec) / 1e6) / N);
  }
  unsigned char *px = malloc((size_t)W * H * 4); glReadPixels(0, 0, W, H, GL_RGBA, GL_UNSIGNED_BYTE, px);
  FILE *o = fopen(argv[8], "wb");
  fprintf(o, "P7\nWIDTH %d\nHEIGHT %d\nDEPTH 4\nMAXVAL 255\nTUPLTYPE RGB_ALPHA\nENDHDR\n", W, H);
  for (int y = H - 1; y >= 0; y--) fwrite(px + (size_t)y * W * 4, 1, (size_t)W * 4, o);   // GL rows are bottom-up
  fclose(o); return 0;
}
