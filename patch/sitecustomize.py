"""
Allow executables outside their Proton prefixes in Bottles.

Patches only bottles.frontend.windows.umu at import time.
Does not modify installed files.
"""

import ast
import sys
from importlib.abc import Loader, MetaPathFinder
from importlib.machinery import PathFinder

TARGET = "bottles.frontend.windows.umu"
EXPECTED_CHECKS = 5


class PatchPaths(ast.NodeTransformer):
    def __init__(self):
        self.count = 0

    def visit_Call(self, node):
        self.generic_visit(node)

        # Replace path.relative_to(prefix) with None.
        # The original code only calls relative_to() to
        # check containment by catching ValueError.
        if (
            isinstance(node.func, ast.Attribute)
            and node.func.attr == "relative_to"
        ):
            self.count += 1
            return ast.copy_location(
                ast.Constant(value=None),
                node,
            )

        return node


class PatchedLoader(Loader):
    def __init__(self, original):
        self.original = original

    def create_module(self, spec):
        if hasattr(self.original, "create_module"):
            return self.original.create_module(spec)
        return None

    def exec_module(self, module):
        source = self.original.get_source(module.__name__)

        if source is None:
            raise ImportError("Cannot read Bottles UMU source")

        tree = ast.parse(source)
        patch = PatchPaths()
        tree = patch.visit(tree)

        if patch.count != EXPECTED_CHECKS:
            raise ImportError(
                f"Bottles patch: expected {EXPECTED_CHECKS} "
                f"path checks, found {patch.count}"
            )

        ast.fix_missing_locations(tree)

        code = compile(tree, module.__file__, "exec")

        print(
            f"[bottles-patch] Removed {patch.count} prefix checks",
            file=sys.stderr,
        )

        exec(code, module.__dict__)


class PatchFinder(MetaPathFinder):
    def find_spec(self, fullname, path=None, target=None):
        if fullname != TARGET:
            return None

        spec = PathFinder.find_spec(fullname, path)

        if spec and spec.loader:
            if not hasattr(spec.loader, "get_source"):
                raise ImportError("Unsupported Bottles module loader")

            spec.loader = PatchedLoader(spec.loader)

        return spec


sys.meta_path.insert(0, PatchFinder())

print("[bottles-patch] Import hook installed", file=sys.stderr)


