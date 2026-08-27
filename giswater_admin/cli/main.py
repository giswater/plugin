"""``gw`` entrypoint: parse arguments, prepare context, dispatch command."""

from __future__ import annotations

import sys

from ..commands._helpers import SchemaAdminRequired
from ..output import Out, configure_stderr_logging
from .context import prepare_context
from .parser import build_parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    configure_stderr_logging(debug=getattr(args, "debug", False))
    try:
        prepare_context(args)
    except Exception as e:  # noqa: BLE001 - CLI boundary
        if getattr(args, "json", False):
            print(f'{{"ok": false, "error": "{e}"}}', file=sys.stderr)
        else:
            print(str(e), file=sys.stderr)
        return 1

    out = Out(
        json_mode=getattr(args, "json", False),
        quiet=getattr(args, "quiet", False),
        verbose=getattr(args, "verbose", False),
        debug=getattr(args, "debug", False),
        timing=getattr(args, "timing", False),
        sql_root=getattr(args, "dbmodel_path", "") or "",
    )
    try:
        return args.func(args, out)
    except SchemaAdminRequired:
        return 1
    except Exception as e:  # noqa: BLE001 - CLI boundary
        out.error(str(e))
        if getattr(args, "json", False):
            out.result({"ok": False, "error": str(e)})
        return 1


if __name__ == "__main__":
    sys.exit(main())
