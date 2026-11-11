"""UTF-8 cap for the audit activity body. No QGIS, no database."""

import json

from core.utils.activity_body import ACTIVITY_BODY_CAP, shape_activity_body


def _bytes(payload):
    return len(json.dumps(payload, ensure_ascii=False).encode('utf-8'))


def test_ene_counts_as_two_utf8_bytes():
    # 1024 × ñ = 2048 bytes. The key wrapper pushes the stored object over the cap,
    # so the huge value is dropped and only the truncated marker remains.
    node_id = 'ñ' * 1024
    assert len(node_id) == 1024
    assert len(node_id.encode('utf-8')) == 2048
    shaped = shape_activity_body({'action': 'mincutAccept', 'nodeId': node_id})
    assert shaped['truncated'] is True
    assert 'nodeId' not in shaped
    assert shaped['action'] == 'mincutAccept'
    assert _bytes(shaped) <= ACTIVITY_BODY_CAP


def test_short_ene_is_kept():
    shaped = shape_activity_body({'nodeId': 'cañón'})
    assert shaped == {'nodeId': 'cañón'}
    assert 'truncated' not in shaped


def test_unparseable_json_does_not_keep_the_source_text():
    raw = '$${"version":""4.18.0""}$$'
    shaped = shape_activity_body(raw)
    assert shaped['unparseable'] is True
    assert 'bytes' in shaped
    assert '4.18.0' not in json.dumps(shaped)
    assert 'version' not in shaped


def test_preview_is_stripped_and_marked_truncated():
    preview = {'nodes': ['x' * 4000]}
    raw = {
        'client': {'cur_user': 'jlopez', 'device': 4, 'lang': 'es_ES'},
        'form': {},
        'feature': {},
        'data': {
            'parameters': {
                'action': 'ADD',
                'configZone': 'dma',
                'mapzoneId': '4',
                'nodeParent': '9021',
                'config': preview,
                'preview': preview,
                'fields': {'the_geom': 'LINESTRING(0 0, 1 1)'},
                'the_geom': 'LINESTRING(0 0, 1 1)',
            }
        },
    }
    shaped = shape_activity_body(raw)
    dumped = json.dumps(shaped, ensure_ascii=False)
    assert shaped['truncated'] is True
    assert shaped['bytes'] > ACTIVITY_BODY_CAP
    assert shaped['action'] == 'ADD'
    assert shaped['configZone'] == 'dma'
    assert shaped['mapzoneId'] == '4'
    assert shaped['nodeParent'] == '9021'
    assert shaped['client'] == {'cur_user': 'jlopez'}
    assert 'preview' not in shaped
    assert 'LINESTRING' not in dumped
    assert 'x' * 100 not in dumped
    assert _bytes(shaped) <= ACTIVITY_BODY_CAP


def test_dollar_quoting_is_removed_before_parse():
    shaped = shape_activity_body('$${"action": "mincutAccept", "mincutId": 17}$$')
    assert shaped['action'] == 'mincutAccept'
    assert shaped['mincutId'] == 17
    assert 'truncated' not in shaped
