#include <nterm.h>
#include <stdarg.h>
#include <unistd.h>
#include <SDL.h>

char handle_key(SDL_Event *ev);

static void sh_printf(const char *format, ...) {
  static char buf[256] = {};
  va_list ap;
  va_start(ap, format);
  int len = vsnprintf(buf, 256, format, ap);
  va_end(ap);
  term->write(buf, len);
}

static void sh_banner() {
  sh_printf("Built-in Shell in NTerm (NJU Terminal)\n\n");
}

static void sh_prompt() {
  sh_printf("sh> ");
}

static void sh_handle_cmd(const char *cmd) {
  // Pre-process to remove '\n'
  char buf[128] = {};
  strcpy(buf, cmd);
  int len = strlen(buf);
  buf[len - 1] = 0;   

  // Fill argv array
  int argc = 0;
  char *argv[64] = {};
  char delim[2] = {" "};
  char *token = strtok(buf, delim);
  while (token) {
    argv[argc] = token;
    token = strtok(NULL, delim);
    argc ++;
  }
  argv[argc] = NULL;

  // Execute command
  if (argc > 0) {
    execvp(argv[0], argv);
    sh_printf("execute %s failed\n", argv[0]);
  }
}

void builtin_sh_run() {
  sh_banner();
  sh_prompt();

  setenv("PATH", "/bin", 0);

  while (1) {
    SDL_Event ev;
    if (SDL_PollEvent(&ev)) {
      if (ev.type == SDL_KEYUP || ev.type == SDL_KEYDOWN) {
        const char *res = term->keypress(handle_key(&ev));
        if (res) {
          sh_handle_cmd(res);
          sh_prompt();
        }
      }
    }
    refresh_terminal();
  }
}
