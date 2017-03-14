#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define WBY_STATIC
#define WBY_IMPLEMENTATION
#define WBY_USE_FIXED_TYPES
#define WBY_USE_ASSERT
#include "web.h"

#ifdef __APPLE__
#include <unistd.h>
#endif

struct server_state {
    int quit;
    unsigned frame_counter;
    struct wby_con *conn[1];
    int conn_count;
};

static void
sleep_for(long ms)
{
#if defined(__APPLE__)
    usleep(ms * 1000);
#else
    time_t sec = (int)(ms / 1000);
    const long t = ms -(sec * 1000);
    struct timespec req;
    req.tv_sec = sec;
    req.tv_nsec = t * 1000000L;
    while(-1 == nanosleep(&req, &req));
#endif
}

static int
dispatch(struct wby_con *connection, void *userdata)
{
    struct server_state *state = (struct server_state*)userdata;
    if (!strcmp("/latest/meta-data/instance-id", connection->request.uri)) {
        wby_response_begin(connection, 200, 11, NULL, 0);
        wby_write(connection, "i-deadbeef\n", 11);
        wby_response_end(connection);
        return 0;
    } else if (!strcmp("/quit", connection->request.uri)) {
        wby_response_begin(connection, 200, -1, NULL, 0);
        wby_write(connection, "quitting\n", 9);
        wby_response_end(connection);
        state->quit = 1;
        return 0;
    } else return 1;
}

int
main(void)
{
    void *memory = NULL;
    wby_size needed_memory = 0;
    struct server_state state;
    struct wby_server server;

    struct wby_config config;
    memset(&config, 0, sizeof config);
    config.userdata = &state;
    config.address = "169.254.169.254";
    config.port = 80;
    config.connection_max = 1;
    config.request_buffer_size = 2048;
    config.io_buffer_size = 8192;
    config.dispatch = dispatch;

    wby_init(&server, &config, &needed_memory);
    memory = calloc(needed_memory, 1);
    wby_start(&server, memory);

    memset(&state, 0, sizeof state);
    while (!state.quit) {
        int i = 0;
        wby_update(&server);
        sleep_for(30);
        ++state.frame_counter;
    }
    wby_stop(&server);
    free(memory);
    return 0;
}

