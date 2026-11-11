"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import json

# UTF-8 bytes, not characters. ñ is 2 bytes and must count as 2.
ACTIVITY_BODY_CAP = 2048

_KEEP_KEYS = ('action', 'mincutId', 'nodeId', 'mapzoneId', 'configZone', 'nodeParent')
_KEEP_KEY_SET = set(_KEEP_KEYS)
_DROP_KEYS = set(('config', 'preview', 'fields', 'the_geom'))


def cap_utf8(text, limit=ACTIVITY_BODY_CAP):
    """Cut *text* so its UTF-8 encoding is at most *limit* bytes."""
    if text is None:
        return ''
    if not isinstance(text, str):
        text = str(text)
    raw = text.encode('utf-8')
    if len(raw) <= limit:
        return text
    return raw[:limit].decode('utf-8', errors='ignore')


def shape_activity_body(raw):
    """Body stored in audit.activity.

    Keeps action, the listed ids and client.cur_user. Drops config, preview,
    fields and the_geom. Never sends unparseable source text to jsonb.
    """
    text, parsed, n_bytes = _decode_body(raw)
    if parsed is None:
        return {'unparseable': True, 'bytes': n_bytes if text is not None else 0}

    shaped = _pick(parsed)
    over = n_bytes > ACTIVITY_BODY_CAP or _json_bytes(shaped) > ACTIVITY_BODY_CAP
    if not over:
        return shaped

    shaped['truncated'] = True
    shaped['bytes'] = n_bytes
    if _json_bytes(shaped) <= ACTIVITY_BODY_CAP:
        return _ordered_truncated(shaped)

    reduced = {'truncated': True, 'bytes': n_bytes}
    action = shaped.get('action')
    if action is not None:
        reduced['action'] = action
    if _json_bytes(reduced) <= ACTIVITY_BODY_CAP:
        return reduced
    return {'truncated': True, 'bytes': n_bytes}


def _decode_body(raw):
    if raw is None:
        return None, {}, 2
    if isinstance(raw, dict):
        try:
            text = json.dumps(raw, ensure_ascii=False, default=str)
        except (TypeError, ValueError):
            text = ''
        return text, raw, len(text.encode('utf-8'))
    if not isinstance(raw, str):
        raw = str(raw)
    text = raw.strip()
    if text.startswith('$$') and text.endswith('$$') and len(text) >= 4:
        text = text[2:-2]
    n_bytes = len(text.encode('utf-8'))
    try:
        parsed = json.loads(text)
    except (TypeError, ValueError):
        return text, None, n_bytes
    if not isinstance(parsed, dict):
        return text, {'_value': parsed}, n_bytes
    return text, parsed, n_bytes


def _pick(data):
    found = {}
    _walk(data, found)
    shaped = {}
    cur_user = _cur_user(data)
    if cur_user not in (None, ''):
        shaped['client'] = {'cur_user': cur_user}
    for key in _KEEP_KEYS:
        if key in found:
            shaped[key] = found[key]
    return shaped


def _walk(node, found):
    if isinstance(node, dict):
        for key, value in node.items():
            if key in _DROP_KEYS:
                continue
            if key in _KEEP_KEY_SET and key not in found:
                found[key] = value
                continue
            _walk(value, found)
    elif isinstance(node, list):
        for item in node:
            _walk(item, found)


def _cur_user(node):
    if isinstance(node, dict):
        client = node.get('client')
        if isinstance(client, dict) and client.get('cur_user') not in (None, ''):
            return client.get('cur_user')
        for key, value in node.items():
            if key in _DROP_KEYS:
                continue
            found = _cur_user(value)
            if found not in (None, ''):
                return found
    elif isinstance(node, list):
        for item in node:
            found = _cur_user(item)
            if found not in (None, ''):
                return found
    return None


def _json_bytes(payload):
    return len(json.dumps(payload, ensure_ascii=False, default=str).encode('utf-8'))


def _ordered_truncated(shaped):
    ordered = {'truncated': True, 'bytes': shaped.get('bytes')}
    if 'client' in shaped:
        ordered['client'] = shaped['client']
    for key in _KEEP_KEYS:
        if key in shaped:
            ordered[key] = shaped[key]
    return ordered
