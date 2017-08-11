#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <netdb.h>

#include <lua.h>
#include <lauxlib.h>
#include <auxlib.h>

#define BUFSZ 4096
#define TIMEOUT 10

static int
udp(lua_State *L)
{
	const char *ip = luaL_checkstring(L, 1);
	lua_Number port = luaL_checknumber(L, 2);
	const char *payload;
	size_t payload_sz;
	char buf[BUFSZ] = {0};
	char rbuf[BUFSZ] = {0};
	struct timeval tv = {0};
	struct sockaddr_in dst = {0};
	struct sockaddr_in src = {0};
	struct sockaddr_in resp_src = {0};
	time_t start;
	time_t now;
	int fd;
	socklen_t socklen;
	fd_set set;
	int r_select;
	ssize_t recvfrom_r;
	int saved;

	errno = 0;
	if (lua_gettop(L) < 2) return luaX_pusherror(L, "Not enough arguments.");

	errno = 0;
	fd = socket(AF_INET, SOCK_DGRAM, 0);
	if (0 > fd) return luaX_pusherror(L, "socket(2) error in udp().");

	src.sin_family = AF_INET;
	src.sin_addr.s_addr = htonl(INADDR_ANY);
	src.sin_port = htons(0);

	errno = 0;
	if (0 > bind(fd, (struct sockaddr *)&src, sizeof(src))) {
		saved = errno;
		shutdown(fd, SHUT_RDWR);
		close(fd);
		errno = saved;
		return luaX_pusherror(L, "bind(2) error in udp().");
	}
	dst.sin_family = AF_INET;
	errno = 0;
	if (0 > inet_pton(AF_INET, ip, &dst.sin_addr.s_addr)) {
		saved = errno;
		shutdown(fd, SHUT_RDWR);
		close(fd);
		errno = saved;
		return luaX_pusherror(L, "inet_pton(2) error in udp().");
	}
	dst.sin_port = htons(port);
	if (3 == lua_gettop(L)) {
		payload = luaL_checkstring(L, 3);
		payload_sz = lua_rawlen(L, 3);
		if (payload_sz > BUFSZ) payload_sz = BUFSZ;
		memcpy(buf, payload, payload_sz);
	} else {
		payload_sz = 1;
		buf[0] = '\0';
	}

	errno = 0;
	if (0 > sendto(fd, buf, payload_sz, 0, (struct sockaddr *)&dst, sizeof(dst))) {
		saved = errno;
		shutdown(fd, SHUT_RDWR);
		close(fd);
		errno = saved;
		return luaX_pusherror(L, "sendto(2) error in udp().");
	}

	time(&start);
	while(1) {
		tv = (struct timeval){0};
		time(&now);
		if (TIMEOUT <= now-start) {
			errno = 0;
			return luaX_pusherror(L, "udp() timed out.");
		}
		tv.tv_sec = TIMEOUT-(now-start);
		tv.tv_usec = 0;
		FD_ZERO(&set);
		FD_SET(fd, &set);
		errno = 0;
		r_select = select(fd+1, &set, NULL, NULL, &tv);
		if (!r_select) {
			saved = errno;
			shutdown(fd, SHUT_RDWR);
			close(fd);
			errno = saved;
			return luaX_pusherror(L, "select(2) timed out.");
		}
		if (0 > r_select) {
			saved = errno;
			shutdown(fd, SHUT_RDWR);
			close(fd);
			errno = saved;
			return luaX_pusherror(L, "select(2) error in udp().");
		}
		if(!FD_ISSET(fd, &set)) continue;
		socklen = sizeof(struct sockaddr_in);
		errno = 0;
		recvfrom_r = recvfrom(fd, rbuf, BUFSZ, 0, (struct sockaddr *)&resp_src, &socklen);
		saved = errno;
		shutdown(fd, SHUT_RDWR);
		close(fd);
		errno = saved;
		if (0 > recvfrom_r) return luaX_pusherror(L, "recvfrom(2) error in udp().");
		lua_pushlstring(L, rbuf, (size_t)recvfrom_r);
		lua_pushstring(L, inet_ntoa(resp_src.sin_addr));
		lua_pushinteger(L, htons(resp_src.sin_port));
		return 3;
	}
}

static const
luaL_Reg send_funcs[] =
{
	{"udp", udp},
	{NULL, NULL}
};

int
luaopen_qsocket(lua_State *L)
{
	luaL_newlib(L, send_funcs);
	return 1;
}
