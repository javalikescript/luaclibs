// see changemain.lua

int main (int argc, char **argv) {
  int status;
  char **rargv;
  int rargc;
  char **parg;
  char *papp;
  char *pscr;
  if (argv[0] == NULL) {
    return 1; // not supported
  }
#if defined(_WIN32)
  papp = strrchr(argv[0], '\\');
#else
  papp = strrchr(argv[0], '/');
#endif
  if (papp == NULL) {
    papp = argv[0];
  }
  pscr = getenv("JLS_LUA_PROGNAME");
  if (pscr == NULL) {
    pscr = LUA_PROGNAME;
  }
  if (strstr(papp, pscr) != NULL) {
    return base_main(argc, argv);
  }
  rargv = malloc(sizeof(char *) * (argc + 6));
  if (rargv == NULL) {
    return 12;
  }
  rargc = 0;
  rargv[rargc++] = argv[0];
#if defined(CUSTOM_EXECUTE)
  pscr = NULL;
  rargv[rargc++] = "-e";
  rargv[rargc++] = CUSTOM_EXECUTE;
  rargv[rargc++] = argv[0]; // fake script name
#else
  pscr = malloc(sizeof(char) * (strlen(argv[0]) + 5));
  if (pscr == NULL) {
    free(rargv);
    return 12;
  }
  sprintf(pscr, "%s.lua", argv[0]);
  rargv[rargc++] = pscr;
#endif
  for (parg = argv + 1; *parg; parg++) {
    rargv[rargc++] = *parg;
  }
  rargv[rargc] = NULL;
  //for (int i = 0; rargv[i]; i++) printf("%d:\t%s\n", i, rargv[i]);
  status = base_main(rargc, rargv);
  free(rargv);
  free(pscr);
  return status;
}
