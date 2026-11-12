"""Private JSON transport for native Python Babel blocks (no Emacs dependency)."""
import ast
import json
import math
import os
import sys
import tempfile
import traceback

protocol = os.fdopen(os.dup(1), "w", encoding="utf-8", buffering=1)
original_stdout_fd, original_stderr_fd = os.dup(1), os.dup(2)
token = sys.argv[1]
namespace = {"__name__": "__main__"}


def portable(value, table=False):
    if isinstance(value, float) and not math.isfinite(value):
        return repr(value)
    if value is None or isinstance(value, (str, bool, int, float)):
        return value
    if isinstance(value, (list, tuple)):
        return [portable(item, table) for item in value]
    if table and hasattr(value, "tolist"):
        return portable(value.tolist())
    if table and hasattr(value, "values") and hasattr(value.values, "tolist"):
        return portable(value.values.tolist())
    return repr(value)


def run(request):
    old_cwd = os.getcwd()
    old_path = sys.path[:]
    saved_stdout, saved_stderr, saved_stdin = sys.stdout, sys.stderr, sys.stdin
    value, status = None, 0
    with tempfile.TemporaryFile() as out, tempfile.TemporaryFile() as err:
        try:
            sys.stdout.flush()
            sys.stderr.flush()
            os.dup2(out.fileno(), 1)
            os.dup2(err.fileno(), 2)
            os.chdir(request["cwd"])
            sys.path.insert(0, request["cwd"])
            # input() must not consume the worker's protocol stream.
            sys.stdin = open(os.devnull, encoding="utf-8")
            namespace.update(request.get("variables", {}))
            code, filename = request["code"], request["filename"]
            if request["mode"] == "value" and not request.get("session"):
                body = "\n".join("    " + line for line in code.splitlines()) or "    pass"
                wrapped = "def __org_workbench_block__():\n" + body + "\n"
                exec(compile(wrapped, filename, "exec"), namespace)
                value = namespace["__org_workbench_block__"]()
            elif request["mode"] == "value":
                tree = ast.parse(code, filename)
                last = tree.body.pop() if tree.body and isinstance(tree.body[-1], ast.Expr) else None
                exec(compile(tree, filename, "exec"), namespace)
                if last:
                    value = eval(compile(ast.Expression(last.value), filename, "eval"), namespace)
            else:
                exec(compile(code, filename, "exec"), namespace)
            if request.get("graphics"):
                import matplotlib.pyplot as plt
                figure = value if hasattr(value, "savefig") else plt.gcf()
                figure.savefig(request["file"])
                value = request["file"]
            value = portable(value, request.get("table", False))
        except BaseException:
            status = 1
            traceback.print_exc()
        finally:
            try:
                sys.stdout.flush()
                sys.stderr.flush()
            except BaseException:
                pass
            os.dup2(original_stdout_fd, 1)
            os.dup2(original_stderr_fd, 2)
            if sys.stdin is not saved_stdin:
                sys.stdin.close()
            sys.stdout, sys.stderr, sys.stdin = saved_stdout, saved_stderr, saved_stdin
            os.chdir(old_cwd)
            sys.path[:] = old_path
        limit = request.get("max_output_bytes", 1000000)
        out.seek(0)
        err.seek(0)
        stdout = out.read(limit + 1).decode("utf-8", "replace")
        stderr = err.read(limit + 1).decode("utf-8", "replace")
        if len(stdout.encode()) > limit:
            stdout = stdout[:limit] + "\n[Saída truncada]"
        if len(stderr.encode()) > limit:
            stderr = stderr[:limit] + "\n[Saída truncada]"
        return {"stdout": stdout, "stderr": stderr, "code": status, "signal": 0, "value": value}


for line in sys.stdin:
    try:
        request = json.loads(line)
        response = run(request)
        response["id"] = request["id"]
    except BaseException:
        response = {"code": 1, "stderr": traceback.format_exc(), "stdout": ""}
    protocol.write(token + json.dumps(response, ensure_ascii=True, allow_nan=False) + "\n")
    if "--once" in sys.argv:
        break
