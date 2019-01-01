local ffi = require "ffi"
local C = ffi.C
local exec = {}

ffi.cdef([[
typedef int32_t pid_t;
pid_t fork(void);
char *strerror(int errnum);
int open(const char *pathname, int flags, int mode);
int close(int fd);
int dup2(int oldfd, int newfd);
int setenv(const char*, const char*, int);
int execvp(const char *file, char *const argv[]);
]])
local ffi_error = function(s)
  s = s or "error"
  return string.format("%s: %s\n", s, ffi.string(C.strerror(ffi.errno())))
end
local octal = function(n) return tonumber(n, 8) end
local STDOUT = 1
local STDERR = 2

-- dest should be either 0 or 1 (STDOUT or STDERR)
local redirect = function(io_or_filename, dest_fd)
    if io_or_filename == nil then return true end
    local O_WRONLY = octal('0001')
    local O_CREAT  = octal('0100')
    local S_IRUSR  = octal('00400') -- user has read permission
    local S_IWUSR  = octal('00200') -- user has write permission
    -- first check for regular
    if (io_or_filename == io.stdout or io_or_filename == STDOUT) and dest_fd ~= STDOUT then
        C.dup2(STDERR, STDOUT)
    elseif (io_or_filename == io.stderr or io_or_filename == STDERR) and dest_fd ~= STDERR then
        C.dup2(STDOUT, STDERR)

    -- otherwise handle file-based redirection
    else
        local fd = C.open(io_or_filename, bit.bor(O_WRONLY, O_CREAT), bit.bor(S_IRUSR, S_IWUSR))
        if fd < 0 then
          return nil, ffi_error(string.format("failure opening file '%s'", fname))
        end
        C.dup2(fd, dest_fd)
        C.close(fd)
    end
end

exec.spawn = function (exe, args, cwd, env, stdout_redirect, stderr_redirect)
    args = args or {}

    local pid = C.fork()
    if pid < 0 then
        return nil, ffi_error("fork(2) failed")
    elseif pid == 0 then -- child process
        redirect(stdout_redirect, STDOUT)
        redirect(stderr_redirect, STDERR)
        local string_array_t = ffi.typeof('const char *[?]')
        --local char_p_k_p_t   = ffi.typeof('char *const*')
        -- args is 1-based Lua table, argv is 0-based C array
        -- automatically NULL terminated
        local argv = string_array_t(#args + 1 + 1)
        for i = 1, #args do
            argv[i] = tostring(args[i])
        end
        do
          local function setenv(name, value)
            local overwrite_flag = 1
            if C.setenv(name, value, overwrite_flag) == -1 then
              return nil, ffi_error("setenv(3) failed")
            else
              return value
            end
          end
          for name, value in pairs(env or {}) do
            local x, e = setenv(name, tostring(value))
            if x == nil then return nil, e end
          end
        end
        --if cwd then C.chdir(tostring(cwd)) end
        argv[0] = exe
        argv[#args + 1] = nil
        if C.execvp(exe, ffi.cast("char *const*", argv)) == -1 then
          return nil, ffi_error("execvp(3) failed")
        end
        assert(nil, "assertion failed: exec.spawn (should be unreachable!)")
    end
end

return exec
