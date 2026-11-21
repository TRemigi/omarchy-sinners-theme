// Developer tool: runs a fragment shader on Mesa's software GL (headless EGL) and writes the frame as a PAM image
// (premultiplied RGBA), so a shader can be looked at without a GPU or a compositor. tools/preview-embers.sh and
// tools/preview-burn.sh build and call it.
//
//   usage: shader-harness shader.frag W H time seed intensity density out.pam
//   shader.frag is the GLES variant: qsb -x "glsl,100 es" -o shader.frag name.frag.qsb
//   SOURCE=card.pam binds a picture (straight alpha, premultiplied here as Qt's layer textures are) to the
//     shader's `source` sampler, as a layer effect gets.
//   WEAR=mask.pam binds a second picture (RGBA PAM, used as it is) to a `wear` sampler on texture unit 2; the bar's
//     lettering shader reads its mask from there.
//   FLOATS="progress=0.4,dur=1.2" and VEC2="size=380:76,origin=40:70" set more uniforms by name (ubuf.NAME).
//   For smoke.frag: AMOUNT (default 0.32) is how much smoke; the sun's position is worked out from W and H the way
//   the plugin does (the wallpaper is 3840x2160 with its sun at 1920,940 and radius 600, scaled to cover the screen).
//   Uniforms a shader does not have are ignored.
//   FRAMES=N also times N further draws (ms per draw on stderr; llvmpipe, so not GPU timings).
//
// This tests the shader, not the Qt integration. qt_TexCoord0 has y = 0 at the top, as in Qt.
#include <EGL/egl.h>
#include <GLES3/gl3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>

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

// Binds the RGBA PAM named by environment variable `env` to texture unit `unit` as the sampler `name`. premul = 1
// premultiplies it first (Qt's layer textures are premultiplied). Returns 0 when the variable is unset, else exits on error.
static int bind_pam(GLuint prog, const char *env, int unit, const char *name, int premul) {
  if (!getenv(env)) return 0;
  FILE *f = fopen(getenv(env), "rb"); if (!f) { perror(env); exit(7); }
  char line[128]; int iw = 0, ih = 0, depth = 4;
  while (fgets(line, sizeof line, f)) {
    sscanf(line, "WIDTH %d", &iw); sscanf(line, "HEIGHT %d", &ih); sscanf(line, "DEPTH %d", &depth);
    if (!strncmp(line, "ENDHDR", 6)) break;
  }
  if (iw <= 0 || ih <= 0 || depth != 4) { fprintf(stderr, "%s must be an RGBA PAM\n", env); exit(7); }
  unsigned char *img = malloc((size_t)iw * ih * 4);
  if (fread(img, 1, (size_t)iw * ih * 4, f) != (size_t)iw * ih * 4) { fprintf(stderr, "%s is short\n", env); exit(7); }
  fclose(f);
  if (premul) for (size_t i = 0; i < (size_t)iw * ih; i++) for (int c = 0; c < 3; c++) img[i * 4 + c] = (unsigned char)(img[i * 4 + c] * img[i * 4 + 3] / 255.f + 0.5f);
  GLuint tx; glActiveTexture(GL_TEXTURE0 + unit); glGenTextures(1, &tx); glBindTexture(GL_TEXTURE_2D, tx);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, iw, ih, 0, GL_RGBA, GL_UNSIGNED_BYTE, img);   // first row = top, v = 0
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glUniform1i(glGetUniformLocation(prog, name), unit);
  glActiveTexture(GL_TEXTURE0);
  free(img);
  return 1;
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
  glUniform1f(glGetUniformLocation(prog, "ubuf.amount"), getenv("AMOUNT") ? (float)atof(getenv("AMOUNT")) : 0.32f);
  { float sc = (float)W / 3840.f > (float)H / 2160.f ? (float)W / 3840.f : (float)H / 2160.f;   // cover-fit scale
    float sx = ((1920.f - 1920.f) * sc + W / 2.f) / H, sy = 1.f - ((940.f - 1080.f) * sc + H / 2.f) / H, sr = 600.f * sc / H;
    glUniform3f(glGetUniformLocation(prog, "ubuf.sun"), sx, sy, sr); }

  // Extra uniforms by name: FLOATS="a=1,b=2", VEC2="c=1:2".
  { const char *lists[2] = { getenv("FLOATS"), getenv("VEC2") };
    for (int k = 0; k < 2; k++) {
      if (!lists[k]) continue;
      char *copy = strdup(lists[k]), *save = NULL;
      for (char *tok = strtok_r(copy, ",", &save); tok; tok = strtok_r(NULL, ",", &save)) {
        char name[64], full[80]; float a = 0, b = 0;
        if (k == 0 && sscanf(tok, "%63[^=]=%f", name, &a) == 2) { snprintf(full, sizeof full, "ubuf.%s", name); glUniform1f(glGetUniformLocation(prog, full), a); }
        if (k == 1 && sscanf(tok, "%63[^=]=%f:%f", name, &a, &b) == 3) { snprintf(full, sizeof full, "ubuf.%s", name); glUniform2f(glGetUniformLocation(prog, full), a, b); }
      }
      free(copy);
    } }

  // A picture for the `source` sampler (texture unit 1, as in Qt's layer effects), from a PAM with straight alpha; and
  // optionally a second for `wear` (unit 2).
  bind_pam(prog, "SOURCE", 1, "source", 1);
  bind_pam(prog, "WEAR", 2, "wear", 0);

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
