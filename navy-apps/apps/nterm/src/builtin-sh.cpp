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
  int nr_argv = 0;
  char *argv[8] = {};

  /* Process command */
  char str[64] = {};
  strcpy(str, cmd);
  for (int i = 0; i < 64; i++) {
    if (str[i] == '\n') str[i] = ' ';
  }

  /* Partition command */
  char *token = NULL;
  const char s[2] = " ";
   
  token = strtok(str, s);
  while(token != NULL) {
    argv[nr_argv ++] = token;
    token = strtok(NULL, s);
  }

  if (nr_argv >= 1) {
    /* Examine exit command */
    if (!strcmp(argv[0], "exit") || !strcmp(argv[0], "e")) {
  #ifdef __ISA_NATIVE__
    /* 0 means that exit  */
    exit(0);
  #else
    /* n means that exit entirly */
    exit('n');
  #endif
    }

    /* Execute command */
    execvp(argv[0], argv);
    sh_printf("exec %s failed\n", argv[0]);
  }
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
