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
  int i = 0;
  const char *p = cmd;
  char command[64] = {0};

  /* Process command */
  while (*p != '\n') {
    command[i] = *p;
    i++;
    p++;
  }
  command[i] = 0;

  /* Examine exit command */
  if (!strcmp(command, "exit") || !strcmp(command, "e")) {
#ifdef __ISA_NATIVE__
    /* 0 means that exit  */
    exit(0);
#else
    /* n means that exit entirly */
    exit('n');
#endif
  }

  /* Execute command */
  execvp(command, NULL);
  sh_printf("exec %s failed\n", command);
}

void builtin_sh_run() {
  sh_banner();
  sh_prompt();

  setenv("PATH", "/bin/", 1);

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
