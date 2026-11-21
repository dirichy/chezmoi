// Isolated librime input check; every writable path is supplied by the fixture runner.
#include <rime_api.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
  if (argc != 7) return 2;
  if (!dlopen(argv[5], RTLD_NOW | RTLD_GLOBAL)) { fprintf(stderr,"%s\n",dlerror()); return 6; }
  RimeApi *api = rime_get_api();
  RIME_STRUCT(RimeTraits, traits);
  traits.shared_data_dir = argv[6];
  traits.user_data_dir = argv[1];
  traits.log_dir = argv[1];
  traits.app_name = "rime.radical-test";
  traits.min_log_level = 2;
  const char *modules[] = {"default", "deployer", "lua", NULL};
  traits.modules = modules;
  api->setup(&traits);
  api->initialize(&traits);
  if (!api->deploy_config_file("default.yaml", "config_version")) return 9;
  char schema_path[4096];
  snprintf(schema_path, sizeof(schema_path), "%s/%s.schema.yaml", argv[1], argv[2]);
  char dep[4096];
  snprintf(dep,sizeof(dep),"%s/radical_pinyin.schema.yaml",argv[1]);
  if (!api->deploy_schema(dep)) return 7;
  snprintf(dep,sizeof(dep),"%s/radical_pinyin_flypy.schema.yaml",argv[1]);
  if (!api->deploy_schema(dep)) return 8;
  // A real deployment builds every main schema before the session can switch between them.
  const char *schemas[] = {"tiger", "tiger_full", "rime_ice", "rime_ice_full"};
  for (size_t i = 0; i < sizeof(schemas) / sizeof(schemas[0]); ++i) {
    snprintf(dep, sizeof(dep), "%s/%s.schema.yaml", argv[1], schemas[i]);
    if (!api->deploy_schema(dep)) return 10;
  }
  if (!api->deploy_schema(schema_path)) { fprintf(stderr,"deploy failed\n"); return 3; }
  RimeSessionId session = api->create_session();
  if (!api->select_schema(session, argv[2])) return 4;
  api->set_option(session, "ascii_mode", False);
  api->set_option(session, "simp_hint", False);
  api->set_option(session, "simp_record", False);
  const char *expected = argv[4];
  if (strncmp(expected, "pinyin:", 7) == 0) {
    api->set_option(session, "pinyin", True);
    expected += 7;
  }
  char committed[8192] = {0};
  for (const char *p = argv[3]; *p; ++p) {
    int code = (unsigned char)*p;
    if (code == '\t') code = 0xff09;
    if (code == '\b') code = 0xff08;
    if (code == '\n') code = 0xff0d;
    // Model page clicks and expanded-list clicks (including an item beyond page 1).
    if (code == '\v') api->select_candidate_on_current_page(session, 0);
    else if (code == '\f') api->select_candidate(session, 0);
    else if (code == 0x1d) api->select_candidate(session, 8);
    else api->process_key(session, code, 0);
    RIME_STRUCT(RimeCommit, commit);
    if (api->get_commit(session, &commit)) {
      if (commit.text) strncat(committed, commit.text, sizeof(committed) - strlen(committed) - 1);
      api->free_commit(&commit);
    }
  }
  RIME_STRUCT(RimeContext, ctx);
  api->get_context(session, &ctx);
  printf("%s %s: preedit=%s candidates=", argv[2], argv[3], ctx.composition.preedit ? ctx.composition.preedit : "");
  for (int i=0; i<ctx.menu.num_candidates; ++i) printf(" [%s]",ctx.menu.candidates[i].text);
  puts("");
  int ok = ctx.menu.num_candidates > 0 && strcmp(ctx.menu.candidates[0].text, expected) == 0;
  if (strncmp(expected, "prefix:", 7) == 0) {
    ok = ctx.menu.num_candidates > 0 && strncmp(ctx.menu.candidates[0].text, expected + 7, strlen(expected + 7)) == 0;
  }
  if (strcmp(expected, "format:time") == 0) {
    int h, m, s;
    ok = ctx.menu.num_candidates > 0 && strlen(ctx.menu.candidates[0].text) == 8 &&
      sscanf(ctx.menu.candidates[0].text, "%d:%d:%d", &h, &m, &s) == 3 && h < 24 && m < 60 && s < 60;
  }
  if (strcmp(expected, "format:timestamp") == 0) {
    ok = ctx.menu.num_candidates > 0 && strlen(ctx.menu.candidates[0].text) >= 10 &&
      strspn(ctx.menu.candidates[0].text, "0123456789") == strlen(ctx.menu.candidates[0].text);
  }
  if (strncmp(expected, "comment:", 8) == 0) {
    const char *separator = strchr(expected + 8, '\t');
    size_t text_size = separator ? (size_t)(separator - expected - 8) : 0;
    ok = separator && ctx.menu.num_candidates > 0 &&
      strlen(ctx.menu.candidates[0].text) == text_size &&
      strncmp(ctx.menu.candidates[0].text, expected + 8, text_size) == 0 &&
      ctx.menu.candidates[0].comment &&
      strcmp(ctx.menu.candidates[0].comment, separator + 1) == 0;
    printf("first comment=%s\n", ctx.menu.num_candidates > 0 && ctx.menu.candidates[0].comment ? ctx.menu.candidates[0].comment : "");
  }
  if (strncmp(expected, "second:", 7) == 0) {
    ok = ctx.menu.num_candidates > 1 && strcmp(ctx.menu.candidates[1].text, expected + 7) == 0;
  }
  if (strncmp(expected, "schema:", 7) == 0) {
    char current[256] = {0};
    ok = api->get_current_schema(session, current, sizeof(current)) && strcmp(current, expected + 7) == 0;
    printf("selected schema=%s\n", current);
  }
  if (strncmp(expected, "commit:", 7) == 0) {
    ok = strcmp(committed, expected + 7) == 0;
    printf("committed=%s\n", committed);
  }
  if (strncmp(expected, "option:", 7) == 0) {
    char name[128];
    int enabled;
    ok = sscanf(expected + 7, "%127[^:]:%d", name, &enabled) == 2 &&
      api->get_option(session, name) == enabled && committed[0] == '\0' &&
      ctx.composition.length == 0;
  }
  api->free_context(&ctx);
  api->destroy_session(session);
  api->finalize();
  return ok ? 0 : 5;
}
